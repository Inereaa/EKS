<?php

namespace App\Controller;

use App\Entity\User;
use App\Entity\Post;
use App\Entity\Comment;
use App\Form\PostType;
use App\Form\CommentType;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Doctrine\ORM\EntityManagerInterface;

class WallController extends AbstractController
{
    #[Route('/wall', name: 'app_wall')]
    public function index(EntityManagerInterface $entityManager): Response
    {
        $user = $this->getUser();
        $posts = $entityManager->getRepository(Post::class)->findBy([], ['date' => 'DESC']);

        return $this->render('wall/index.html.twig', [
            'user' => $user,
            'posts' => $posts,
        ]);
    }

    #[Route('/wall/newpost', name: 'app_wall_newpost')]
    public function new(Request $request, EntityManagerInterface $entityManager)
    {
        $post = new Post();
        $user = $this->getUser();
        $post->setAuthor($user);

        $form = $this->createForm(PostType::class, $post);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $post->setDate(new \DateTime());

            $imageFile = $form->get('image')->getData();

            if ($imageFile) {
                $newFilename = uniqid().'.'.$imageFile->guessExtension();
                try {
                    $imageFile->move(
                        $this->getParameter('uploads_directory'),
                        $newFilename
                    );
                    $post->setImage($newFilename);
                } catch (FileException $e) {
                    // errores
                }
            }

            $entityManager->persist($post);
            $entityManager->flush();

            return $this->redirectToRoute('app_wall');
        }

        return $this->render('wall/newpost.html.twig', [
            'form' => $form,
        ]);
    }

    #[Route('/wall/delete/{id}', name: 'app_wall_deletepost', methods: ['POST'])]
    public function deletePost(int $id, EntityManagerInterface $entityManager): Response
    {
        $post = $entityManager->getRepository(Post::class)->find($id);

        if (!$post || $post->getAuthor() !== $this->getUser()) {
            throw $this->createNotFoundException('Publicación no encontrada o no tienes permiso para eliminarla.');
        }

        // eliminar comentarios asociados antes de eliminar el post
        foreach ($post->getComments() as $comment) {
            $entityManager->remove($comment);
        }

        $entityManager->remove($post);
        $entityManager->flush();

        return $this->redirectToRoute('app_wall', ['username' => $this->getUser()->getUsername()]);
    }
 


    #[Route('/wall/{id}/comment', name: 'app_wall_comment')]
    public function comment(Post $post, Request $request, EntityManagerInterface $entityManager): Response
    {
        // crear un nuevo comentario
        $comment = new Comment();
        $comment->setPost($post);
        $comment->setAuthor($this->getUser());
        $comment->setDate(new \DateTime());

        $form = $this->createForm(CommentType::class, $comment);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $entityManager->persist($comment);
            $entityManager->flush();

        }

        return $this->render('wall/comment.html.twig', [
            'form' => $form,
            'post' => $post
        ]);
    }

    #[Route('/wall/{id}/comment/reply', name: 'app_wall_reply')]
    public function reply(int $id, Request $request, EntityManagerInterface $em)
    {
        $comment = $em->getRepository(Comment::class)->find($id);
        if (!$comment) {
            throw $this->createNotFoundException('Comentario no encontrado');
        }

        $reply = new Comment();
        $reply->setPost($comment->getPost());
        $reply->setParent($comment);

        $form = $this->createForm(CommentType::class, $reply);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $reply->setAuthor($this->getUser());
            $reply->setDate(new \DateTime());
            $em->persist($reply);
            $em->flush();

            return $this->redirectToRoute('app_wall_comment', [
                'id' => $comment->getPost()->getId()
            ]) . '#comment-' . $comment->getId();
        }

        return $this->render('wall/reply.html.twig', [
            'form' => $form,
            'comment' => $comment
        ]);
    }


    #[Route('/wall/users', name: 'app_wall_users')]
    public function listUsers(EntityManagerInterface $entityManager): Response
    {
        // obtener todos los usuarios
        $users = $entityManager->getRepository(User::class)->findAll();

        return $this->render('wall/list.html.twig', [
            'users' => $users
        ]);
    }

    #[Route('/wall/users/{id}/wall', name: 'app_wall_user_wall')]
    public function userWall(User $user): Response
    {
        // aquí se puede mostrar el muro del usuario
        return $this->render('wall/index.html.twig', [
            'user' => $user,
        ]);
    }
}
