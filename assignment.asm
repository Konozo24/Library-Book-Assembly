.model small
.stack 100
.data 
    ; Titles and menu options displayed to the user
    title_1 db         "            --------------------$"
    title_2 db 13, 10, "            |    Welcome to    |$"
    title_3 db 13, 10, "            |   Jull Library   |$"
    title_4 db 13, 10, "            --------------------$"
    menu_1 db 13, 10,  "  1. Overdue book Payment       $"
    menu_2 db 13, 10,  "  2. Exit                       $"
    optionMenu db 13, 10,     "  Choose an option: $"
    invalidOptionStr db 13, 10 ,"  Invalid option choice. Please choose 1 OR 2 ONLY. $"

    ; Prompts for inputs and messages displayed during the process
    promptBooks db 13, 10, "Enter number of overdue books: $" 
    promptFine db 13, 10, "Enter fine per overdue book: $"
    invalidQuantitystr db 13, 10, "Invalid quantity. Please try again. $"
    msgTotalFine db 13, 10, "Total fine: $"
    totalAmountstr db 13, 10, "Total Amount to be paid: $"
    insufficientstr db 13, 10, "Insufficient payment. Please input the remaining amount. $"
    changesstr db 13, 10, "Changes: $"
    continuestr db 13, 10, "Continue to add on? (0 to stop): $"
    endstr db 13, 10, "Back to menu? (0 to exit): $"
    
    ; Temporary storage for input values and calculations
    endInput db ? 
    continueInput db ? 
    totalFine dw ? 
    totalAmount dw ? 
    changes dw ? 
    fineperBooks dw ? 
    numBooks dw ? 
    buffer dw 5 dup (?)  ; Buffer for input

    exitTxt db 13, 10, "  Thanks for choosing Jull Library! $"
    optionChoice db ?  ; Stores menu option choice
    endl db 13, 10, '$'  ; endline

.code
main proc 
menu:    
    ; Display the welcome and menu options
    mov ax, @data
    mov ds, ax
    
    mov ah, 09h 
    lea dx, title_1  ; Display first title
    int 21h

    mov ah, 09h 
    lea dx, title_2  ; Display second title
    int 21h

    mov ah, 09h 
    lea dx, title_3  ; Display third title
    int 21h

    mov ah, 09h 
    lea dx, title_4  ; Display fourth title
    int 21h

    mov ah, 09h 
    lea dx, menu_1  ; Display first menu option (overdue payment)
    int 21h

    mov ah, 09h 
    lea dx, menu_2  ; Display second menu option (exit)
    int 21h
    
chooseOption: 
    ; Prompt the user to choose an option
    mov ah, 09h         
    lea dx, optionMenu
    int 21h

    mov ah, 01h  ; Get user input for menu option
    int 21h
    mov optionChoice, al

    ; Validate optionChoice (only 1 or 2 are valid)
    mov al, optionChoice
    cmp al, '1'
    je overduePayment   ; Jump to overdue payment if option 1
    cmp al, '2'
    je exitStr   ; Jump to exit if option 2
     
    ; Invalid choice handling
    mov ah, 09h
    lea dx, invalidOptionStr
    int 21h
    jmp chooseOption  ; Loop back to choose option

exitStr:
    ; Display exit message and terminate
    mov ah, 09h
    lea dx, exitTxt
    int 21h
    jmp exit 
    
exit: 
    mov ax, 4C00h  ; Exit the program
    int 21h

main endp

invalidQuantity:
    ; Display invalid quantity message and restart overdueBook process
    mov ah, 09h
    lea dx, invalidQuantitystr
    int 21h 
    jmp overdueBook 

overduePayment:
    call clearScreen  ; Clear the screen
    call overdueBook  ; Process overdue payment
    jmp menu  ; Return to the menu

overdueBook proc
continuePayment:
    ; Prompt the user to enter the number of overdue books
    mov ah, 09h
    lea dx, promptBooks 
    int 21h

    ; Capture user input for the number of books
    mov byte ptr buffer, 5
    lea dx, buffer
    mov ah, 0Ah 
    int 21h   

    ; Convert string input to number
    lea si, buffer + 2
    call str2num
    mov numBooks, ax 

    ; Validate that number of books is greater than 1
    mov ax, numBooks        
    cmp ax, 1
    jl invalidQuantity

    ; Prompt the user to enter fine per book
    mov ah, 09h
    lea dx, promptFine 
    int 21h

    mov byte ptr buffer, 5 
    lea dx, buffer
    mov ah, 0Ah
    int 21h

    ; Convert string input to fine per book
    lea si, buffer + 2
    call str2num
    mov fineperBooks, ax

    ; Validate fine per book is greater than 1
    mov ax, fineperBooks        
    cmp ax, 1
    jl invalidQuantity

    ; Calculate total fine (number of books * fine per book)
    mov ax, numBooks         
    mov bx, fineperBooks
    mul bx
    add totalFine, ax  ; Add to total fine
    
    ; Display total fine
    mov ah, 09h
    lea dx, msgTotalFine
    int 21h
    mov ax, totalFine
    call printTotaldigit  ; Print total fine in digits

    ; Initialize total amount paid to 0
    mov totalAmount, 0 

    ; Prompt to continue or stop
    mov ah, 09h
    lea dx, continuestr
    int 21h

    mov ah,01h
    int 21h
    mov continueInput, al

    ; If '0', proceed to payment; otherwise, continue adding more books
    mov al, continueInput       
    cmp al, '0'
    je paymentLoop
    jmp continuePayment

paymentLoop:
    ; Prompt for total amount to be paid
    mov ah, 09h
    lea dx, totalAmountstr
    int 21h

    ; Capture user input for total amount
    mov byte ptr buffer, 5
    lea dx, buffer
    mov ah, 0Ah
    int 21h

    ; Convert input and add to total amount paid
    lea si, buffer + 2
    call str2num
    add totalAmount, ax

    ; Check if total amount is less than fine
    mov ax, totalAmount
    cmp ax, totalFine
    jl insufficientChanges  ; Jump if amount paid is less

    ; Calculate and display changes if any
    sub ax, totalFine
    mov changes, ax
    mov ah, 09h
    lea dx, changesstr
    int 21h
    mov ax, changes
    call printTotaldigit 
    jmp finishPayment

insufficientChanges:
    ; Prompt user to input remaining amount if insufficient
    mov ah, 09h
    lea dx, insufficientstr
    int 21h 
    jmp paymentLoop  ; Loop until full payment is made

finishPayment:   
    ; Ask if the user wants to return to the menu
    mov ah, 09h
    lea dx, endstr
    int 21h

    mov ah, 01h
    int 21h 
    mov endInput, al

    ; Display new line and clear screen if user chose to exit
    mov ah, 09h
    lea dx, endl
    int 21h
    mov al, endInput
    cmp al, '0'
    je clearScreen

    ; Reset all values and return to adding more books if needed
    xor ax, ax              
    mov numBooks, ax
    mov fineperBooks, ax
    mov totalFine, ax
    jmp continuePayment
overdueBook endp

; Convert string to number (ASCII to integer)
str2num proc    
    xor ax, ax
currentLoop:     
    mov bl, [si]  ; Load next character
    cmp bl, '0'
    jb stopConvert
    cmp bl, '9'
    ja stopConvert
    sub bl, 30h   ; Convert from ASCII to integer
    mov dx, 10
    mul dx
    add al, bl
    inc si
    jmp currentLoop
stopConvert:
    ret 
str2num endp

; Print number (total fine or changes) as digits
printTotaldigit proc
    xor cx, cx              ; Clear the counter register
    mov bx, 10              ; Set base 10 for division
convertLoop: 
    xor dx, dx              ; Clear the remainder
    div bx                  ; Divide the number by 10 to get the last digit
    push dx                 ; Push the remainder (digit) onto the stack
    inc cx                  ; Increment the digit counter
    cmp ax, 0               ; Check if the quotient is 0
    jnz convertLoop         ; Repeat until all digits are processed

printLoop:
    pop dx                  ; Pop the last digit from the stack
    add dx, 30h             ; Convert the digit to ASCII
    mov ah, 02h             ; DOS function to print a character
    int 21h                 ; Call DOS interrupt to print the digit
    loop printLoop          ; Repeat until all digits are printed

    ret                     ; Return from the procedure
printTotaldigit endp

; Procedure to clear the screen by scrolling the entire screen upwards
clearScreen proc
    mov ah, 06h             ; Scroll the entire screen
    mov bh, 07h             ; Set background and foreground color (light gray on black)
    mov cx, 0               ; Upper-left corner of the screen (row 0, column 0)
    mov dx, 184Fh           ; Lower-right corner of the screen (row 24, column 79)
    int 10h                 ; Call BIOS interrupt to perform the scrolling
    ret                     ; Return from the procedure
clearScreen endp

end main                    ; End of the program
