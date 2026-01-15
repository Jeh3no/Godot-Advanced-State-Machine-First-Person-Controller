An advanced and complete state machine first person controller asset, made in Godot 4.


![Asset logo](https://raw.githubusercontent.com/Jeh3no/Godot-Advanced-State-Machine-First-Person-Controller/refs/heads/main/addons/Arts/logo.png)


# **General**


This asset provides a simple, fully commented, finite state machine based controller, camera, as well as a properties HUD.

A test map is provided to test the controller, with interactive structures allowing to test the various functionalities : slopes, spheres, jumppad (both vertical and directional), gravity area, conveyor area, slippery area

The controller use a finite state machine, designed to be easely editable, allowing to easily add, remove and modify behaviours and actions.

Each state has his own script, allowing to easly filter and manage the communication between each state.

He is also very customizable, with a whole set of open variables for every state and for more general stuff. This is the same for the camera.

The asset is 100% written in GDScript, and respect the GDScript convention.

He works perfectly on Godot 4.5 and Godot 4.4, and should also works well on the others 4.x versions (4.3, 4.2, 4.1, 4.0), but you will have to remove the uid files.

The video showcasing all the changes brought about with the last update (a lot, lot of things) : https://www.youtube.com/watch?v=4PkR2Z1oxG8


# **Features**


 - Finite state machine based controller
 - Smooth moving
 - Ability to move on slopes and hills
 - Walking
 - Crouching (continious and once pressed input)
 - Running (continious and once pressed input)
 - Jumping (multiple jump system)
 - Jump buffering
 - Coyote jump/time
 - Air control (easely customizable thanks to curves)
 - Bunny hopping (+ auto bunny hop)
 - Dashing (multiple dash system)
 - Sliding (on flat surfaces and on slopes)
 - Flying
 - Wallrunning
 - Walljumping

 - Camera FOV management
 - Camera tilt (forward and side tilt)
 - Camera bob
 - Camera zoom
   
 - Reticle
 - Properties HUD

   
# **Purpose**


My main goal with this project is to provide a complete and easy to manage/modify controller for first person games.

I hope that it will be the case.


# **How to use**


It's an asset, which means you can add it to an existing project without any issue.

Simply download it, add it to your project, get the files you want to use.

You will see for the player character script (and in the camera script) a keybinding variables group,

you need to create a input action in your project for each action, and then type the exact same name into the corresponding input action variable.

### Important : if you want to use the input action checker, you must add "play_char_" before any input action related to the player character (movement, camera, hud), both in the input map, and in the script.

(for example : name your move forward action "move_forward", and then type "move_forward" into the variable "move_forward_action").


# **Requets**


- For any bug request, please write on down in the "issues" section.

- For any new feature request, please write it down in the "discussions" section.

- For any bug resolution/improvement commit, please write it down in the "pull requests" section.


# **Credits**

Godot Theme Prototype Textures, by PiCode : https://godotengine.org/asset-library/asset/2480

psychowolf960 (Github account name), for resolving some typo issues, as well as adding the following interactive structures/movement modifiers :
-vertical jump pad
-conveyor area
-slippery area
-gravity area
