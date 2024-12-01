.data
screenStart: 16384    # 0x4000 - Start of the screen
screenEnd: 24576      # 0x6000 - End of the screen
squareColor: 65535    # 0xFFFF - Color of the square
rowShift: 128         # Number of pixels per row
xVelocity: 1          # Initial horizontal velocity
yVelocity: 1          # Initial vertical velocity
squarePos: 16400      # Initial position of the square
delay: 2500           # Delay for smoother movement

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

# Function to check for collisions with the screen edges
checkBounce:
    lw R1, squarePos      # Load the square's current position
    lw R2, rowShift       # Load row shift
    lw R3, xVelocity      # Load horizontal velocity
    lw R4, yVelocity      # Load vertical velocity

    # Check left and right edges
    add R5, R1, R3        # Compute new X position
    slt R6, R5, screenStart # Check if it's less than screenStart
    bne R6, R0, reverseX   # Reverse X direction if hitting the left edge

    lw R6, screenEnd      # Load screenEnd
    slt R6, R5, R6        # Check if it's beyond screenEnd
    beq R6, R0, reverseX  # Reverse X direction if hitting the right edge

    # Check top and bottom edges
    add R5, R1, R4        # Compute new Y position
    slt R6, R5, screenStart # Check if it's less than screenStart
    bne R6, R0, reverseY   # Reverse Y direction if hitting the top edge

    lw R6, screenEnd      # Load screenEnd
    slt R6, R5, R6        # Check if it's beyond screenEnd
    beq R6, R0, reverseY  # Reverse Y direction if hitting the bottom edge

    j bounceDone          # Skip if no collision

reverseX:
    sub R3, R0, R3        # Reverse horizontal velocity
    sw R3, xVelocity

reverseY:
    sub R4, R0, R4        # Reverse vertical velocity
    sw R4, yVelocity

bounceDone:
    jr R7

# Main function
main:
    lw R1, squareColor    # Load the square color

mainLoop:
    jal clearSquare       # Clear the square at the current position
    jal checkBounce       # Check for collisions
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