.data
screenStart: 16384      # 0x4000 - Start of the screen
screenEnd: 24576        # 0x6000 - End of the screen
squareColor: 65535      # 0xFFFF - Color of the square
rowShift: 128           # Number of pixels per row
xVelocity: 1            # Initial horizontal velocity
yVelocity: 1            # Initial vertical velocity
squarePos: 16400        # Initial position of the square
delay: 2500             # Delay for smoother movement
keyboardMem: 24576      # 0x6000 - Address of keyboard memory
upKey: 38               # Key for moving up
downKey: 40             # Key for moving down
leftKey: 37             # Key for moving left
rightKey: 39            # Key for moving right

.text
j main

# Function to draw the square at the current position
drawSquare:
    lw R2, squarePos      # Load the square's current position
    lw R3, rowShift       # Row shift for moving vertically

    # Draw the square (2x2 pixels)
    sw R1, 0(R2)          # Top-left pixel
    sw R1, 1(R2)          # Top-right pixel
    add R2, R2, R3        # Move to the next row
    sw R1, 0(R2)          # Bottom-left pixel
    sw R1, 1(R2)          # Bottom-right pixel

    jr R7

# Function to clear the square at the current position
clearSquare:
    lw R2, squarePos      # Load the square's current position
    lw R3, rowShift       # Row shift for moving vertically

    # Clear the square (set color to 0)
    sw R0, 0(R2)          # Top-left pixel
    sw R0, 1(R2)          # Top-right pixel
    add R2, R2, R3        # Move to the next row
    sw R0, 0(R2)          # Bottom-left pixel
    sw R0, 1(R2)          # Bottom-right pixel

    jr R7

# Function to handle keyboard input and adjust velocities
handleKeyboard:
    lw R2, keyboardMem    # Load the keyboard input
    lw R2, 0(R2)          # Read the key pressed

    # Check for up arrow key
    lw R3, upKey
    beq R2, R3, moveUp

    # Check for down arrow key
    lw R3, downKey
    beq R2, R3, moveDown

    # Check for left arrow key
    lw R3, leftKey
    beq R2, R3, moveLeft

    # Check for right arrow key
    lw R3, rightKey
    beq R2, R3, moveRight

    # No valid key pressed; return
    jr R7

moveUp:
    addi R4, R0, -1       # Set vertical velocity to -1
    sw R4, yVelocity
    jr R7

moveDown:
    addi R4, R0, 1        # Set vertical velocity to +1
    sw R4, yVelocity
    jr R7

moveLeft:
    addi R3, R0, -1       # Set horizontal velocity to -1
    sw R3, xVelocity
    jr R7

moveRight:
    addi R3, R0, 1        # Set horizontal velocity to +1
    sw R3, xVelocity
    jr R7

# Main function
main:
    lw R1, squareColor    # Load the square color

mainLoop:
    jal clearSquare       # Clear the square at the current position
    jal handleKeyboard    # Handle keyboard input
    lw R3, xVelocity      # Load horizontal velocity
    lw R4, yVelocity      # Load vertical velocity
    lw R2, squarePos      # Load current square position

    # Update square position
    add R2, R2, R3        # Update X position
    add R2, R2, R4        # Update Y position
    sw R2, squarePos      # Store the new position

    jal drawSquare        # Draw the square at the new position

    # Delay loop for smoother movement
    lw R5, delay
delayLoop:
    addi R5, R5, -1
    bne R5, R0, delayLoop

    display               # Refresh the screen
    j mainLoop            # Repeat the loop

    jr R7