<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;

use App\Entity\Post;
use Symfony\Contracts\HttpClient\HttpClientInterface;

final class ApiController extends AbstractController
{
    // MICROSERVICIO SIN AUTENTIFICAR
    // http://localhost:8000/api/posts/(FECHA EN FORMATO: 'año-mes-día')
    // ejemplo -> http://localhost:8000/api/posts/2025-02-07
    #[Route('/api/posts/{date}', name: 'api_posts_by_date', methods: ['GET'])]
    public function getPostsByDate(string $date, EntityManagerInterface $entityManager): Response
    {
        try {
            // convertir la fecha en un objeto DateTime
            $dateTime = new \DateTime($date);
        } catch (\Exception $e) {
            return $this->json([
                'error' => 'Fecha no válida. Formato esperado: YYYY-MM-DD.'
            ], Response::HTTP_BAD_REQUEST);
        }

        // establecer el rango de la fecha para obtener publicaciones de ese día
        $startDate = (clone $dateTime)->setTime(0, 0, 0);
        $endDate = (clone $dateTime)->setTime(23, 59, 59);

        // consultar publicaciones entre el rango de fechas
        $posts = $entityManager->getRepository(Post::class)->createQueryBuilder('p')
            ->where('p.date BETWEEN :start AND :end')
            ->setParameter('start', $startDate)
            ->setParameter('end', $endDate)
            ->orderBy('p.date', 'DESC')
            ->getQuery()
            ->getResult();

        // formatear las publicaciones para JSON
        $data = array_map(function (Post $post) {
            return [
                'id' => $post->getId(),
                'content' => $post->getContent(),
                'author' => $post->getAuthor()->getUsername(),
                'date' => $post->getDate()->format('Y-m-d H:i:s')
            ];
        }, $posts);

        return $this->json($data);
    }

    // MICROSERVICIO AUTENTICADO
    // EN POSTMAN ME HA FUNCIONADO TODO PERFECTAMENTE
    // con: http://127.0.0.1:8000/api/login y poniendo mis credenciales como JSON, me devuelve el TOKEN
    // y luego, con: http://127.0.0.1:8000/api/mispublicaciones e introduciendo el TOKEN con 'Bearer', me devuelve los comentarios
    // con sus respuestas
    #[Route('/usuario/login', name: 'app_usuario_login')]
    public function login(HttpClientInterface $httpClient, Request $request): Response
    {
        # Obtenemos el username y el password pasados como parámetros en la url al cliente
        $username = $request->query->get('username');
        $password = $request->query->get('password');

        # Lanzamos la petición proporcionando el username y el password
        $response = $httpClient->request('POST', 'http://localhost:8000/api/login', [
            'json' => [
                'username' => $username,
                'password' => $password
            ]
        ]);
        # Decodificamos la respuesta para obtener el token
        $json = json_decode($response->getContent(),true);
        # Guardamos el token en la sesión
        $request->getSession()->set('token', $json['token']);
        # Devolvemos, también, el token como respuesta al navegador
        return new Response($json['token']);
    }

    #[Route('/usuario/logintoken', name: 'app_usuario_logintoken')]
    public function jsonpedidos(HttpClientInterface $httpClient, Request $request): Response
    {
        # Nos identificamos previamente para que obtener el token (a través de la sesión o de la respuesta)
        $response = $this->login($httpClient, $request);        
        # Recuperamnos el token a a través de la respuesta
        $jwtToken = $response->getContent();
        # También podríamos obtenerlo de la sesión si lo hemnos guardado en $this->login()
        # $jwtToken = $request->getSession()->get('token');

        # Lanzamos la petición proporcionando el login
        $respuesta = $httpClient->request('POST', 'http://localhost:8000/api/logintoken', [
            'headers' => [
                'Authorization' => "Bearer $jwtToken",
                'Accept' => 'application/json',
            ]]);

        # Devolvemos el la respuesta
        return new Response($respuesta->getContent());
    } 

    #[Route('/api/mispublicaciones', name: 'app_api_mis_publicaciones', methods: ['GET'])]
    public function misPublicaciones(EntityManagerInterface $em, Security $security): JsonResponse
    {
        // Obtener el usuario autenticado desde el token JWT
        $usuario = $security->getUser();

        // Verificar si el usuario está autenticado
        if (!$usuario) {
            return new JsonResponse(['error' => 'Acceso no autorizado'], JsonResponse::HTTP_UNAUTHORIZED);
        }

        // Obtener las publicaciones del usuario autenticado
        $publicaciones = $em->getRepository(Post::class)->findBy(['author' => $usuario]);

        // Formatear la respuesta JSON
        $datos = array_map(function($post) {
            return [
                'id' => $post->getId(),
                'contenido' => $post->getContent(),
                'fecha' => $post->getDate()->format('d/m/Y H:i'),
                'comentarios' => array_map(function($comentario) {
                    return [
                        'id' => $comentario->getId(),
                        'contenido' => $comentario->getContent(),
                        'fecha' => $comentario->getDate()->format('d/m/Y H:i'),
                    ];
                }, $post->getComments()->toArray())
            ];
        }, $publicaciones);

        return new JsonResponse($datos);
    }
}
