# hijos_de_fluttarkia

A new Flutter project.

## Getting Started

VinylHub es una aplicación pensada para realizar compra venta de discos de vinilo, que en proximas actualizaciones incorporará
otros formatos físicos como cassette o CD. Para futuras actualizaciones, se añadirá un apartado de coleccción para tener
la colección de cada usuario centralizada y que la app sirva de inventario, así como funcionalidades como "Comunidad", donde los
usuarios puedan publicar posts hablando sobre temas musicales.

Durante el desarrollo de esta app he pasado por varias fases, en las iniciales no fue complicado implementar las funcionalidades
de autenticacion, registro y creación del perfil. La adición de añadir una foto al perfil se hizo un poco complicado ya que al
principio ejecutaba la app en el navegador, y como se puede ver en los commits iniciales, manejaba este asunto con un metodo algo
más complejo de usar en Web.

Tras incorporar las primeras funcionalidades, mi objetivo era el de crear una app accesible para todo el mundo con una UI intuitiva
en la que incorporando un bottomnavigationbar, se pudieran ver a simple vista la mayoría de las funcionalidades que la app ofrece.
Soy consciente de que incorporar cierta parte de la lógica en HomeView, como es la parte en la que se construyen los posts si son
en celda o en grid, o como por ejemplo la pantalla de los chats, no es lo más óptimo como lo sería tenerlo separado en distintas
clases como ya hago con otras partes del código, pero durante el desarrollo final eso cambiará.

Una vez añadidas las funcionalidades de bottomnavigationbar, mi idea era separar la logica de firebaseadmin para centralizar los
métodos de login, registro y demás.

Cuando abordé el tema de los chats, no fue sencillo hacer que un chat fuera privado para dos personas y tuve que crear nuevos
atributos en la coleccion post y chat para que estos fueran accesibles solo entre los dos participantes. También me costó
lograr que al clicar en el boton chat dentro de los detalles del post, no se crearan mas chats sobre el mismo post entre dos
personas y navegara directamente al existente.

Después añadí la colección de favoritos, que es una subcolección de la colección perfiles, en la que cada perfil puede tener muchos
posts como favoritos y un post en concreto puede haber sido marcado como favorito por muchas personas. Para hacerlo mas sencillo y
poder relacionar esta subcolección con la colección posts, solamente añadí el uid del Post como atributo de la subcolección.

Más tarde, incorporé visualmente el perfil de cada usuario, en el que se pueden ver los posts que has subido, aunque aún no he
implementado la edición de estos. Se puede ver la foto de perfil, el correo electrónico, nombre y una puntuación que aún no tiene
funcionalidad ya que estará implementada cuando se añada la valoración de compras entre usuarios.

Por último, uno de los cambios más importantes fue el de conseguir debugear con el dispositivo Android para implementar la subida
de fotos con la cámara del dispositivo, teniendo así que actualizar los métodos de subida de imagen para que estos funcionaran
con storage en vez de con firebase database.

En general el desarrollo ha sido sencillo, aunque han habido algunos puntos en los que me he quedado atascado. Falta mucho trabajo
por hacer, por lo que esta app será mi proyecto final de grado.