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

# Function to draw square at current position
drawSquare:
    lw R2, squarePos
    lw R3, rowShift 

    sw R1, 0(R2)
    sw R1, 1(R2)
    add R2, R2, R3
    sw R1, 0(R2)
    sw R1, 1(R2)

    jr R7

# Clear square at current position
clearSquare:
    lw R2, squarePos
    lw R3, rowShift

    sw R0, 0(R2)
    sw R0, 1(R2)
    add R2, R2, R3
    sw R0, 0(R2)
    sw R0, 1(R2)

    jr R7

handleKeyboard:
    lw R2, keyboardMem
    lw R2, 0(R2)

    # Up
    lw R3, upKey
    beq R2, R3, moveUp

    # Down
    lw R3, downKey
    beq R2, R3, moveDown

    # Left
    lw R3, leftKey
    beq R2, R3, moveLeft

    # Right
    lw R3, rightKey
    beq R2, R3, moveRight

    # Invalid key
    jr R7

moveUp:
    addi R4, R0, -1
    sw R4, yVelocity
    jr R7

moveDown:
    addi R4, R0, 1
    sw R4, yVelocity
    jr R7

moveLeft:
    addi R3, R0, -1
    sw R3, xVelocity
    jr R7

moveRight:
    addi R3, R0, 1
    sw R3, xVelocity
    jr R7

# Main function
main:
    lw R1, squareColor

mainLoop:
    jal clearSquare
    jal handleKeyboard
    lw R3, xVelocity
    lw R4, yVelocity
    lw R2, squarePos

    # Update square position
    add R2, R2, R3
    add R2, R2, R4
    sw R2, squarePos

    jal drawSquare

    # Delay loop for smoother movement
    lw R5, delay

delayLoop:
    addi R5, R5, -1
    bne R5, R0, delayLoop

    display
    j mainLoop

    jr R7