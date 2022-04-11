# Snak
 A clone of Snake, with music and reactive background effects. Made with PICO-8 and a lot of time, care, and stress.

Also available on [itch.io](https://megabyte112.itch.io/snak) and the PICO-8 [Lexaloffle BBS](https://www.lexaloffle.com/bbs/?tid=47268).
 
 ![tbicon](https://user-images.githubusercontent.com/74556753/162636501-06abd034-8ca7-4361-8994-8cd8f5327c31.png)



I spent way too much time making this. It's a clone of snake, and I'm sure you already know the rules. However, the background reacts in time with the music, and the snake also moves in time with the music. There is also a sprint mechanic, so you're not spending 90% of the game just waiting.

There are 4 playable "stages", each with a different song and color scheme. After completing all 4, you have the option to restart in endless mode. You reach the next stage after the snake (known as "Snek") consumes 50 food (known as "Snak"). If Snek collides with the wall or their body, they revert to the beginning of the current stage.

There's some hidden quality of life improvements too, like queueing button presses if you press too quickly, preventing misclicks when sliding adjacent to a wall, and giving a short grace period before a game over.

# This Repository
You will find 3 folders:

"extracted" contains all sound effects, music, sprites, and art used both in-game and outside of the game.

"cart" contains the PICO-8 cartridge as a PNG file, which can be loaded in PICO-8.

"source" contains the raw .p8 file, which can be opened in PICO-8, or any text editor. This is the file that contains all the code that the game runs.

