yardoc --no-private --protected src/controller.rb src/main.rb - README.md LICENSE.md  COPYING.md
yard graph --full -f doc/classes.dot 
dot -Tpng doc/classes.dot  -Gdpi=1000   -o doc/classes.png
#convert doc/classes.png -gravity center -background white -extent 900x1500 doc/classes.png



