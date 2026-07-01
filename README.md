# FPGA-Based Encrypted  Visible Light Communication System  Using Morse Code
<img width="450" height="332" alt="image_93_thumb" src="https://github.com/user-attachments/assets/e3b3641d-f198-47b2-8152-04f79bd523e5" />

FPGA Model : Altera Cyclone IV E EP4CE115F29C7

# Abstract
Visible Light Communication (VLC) is a low-cost wireless communication method that can be implemented using light-emitting devices and camera-based receivers. However, implementing an actual VLC system requires stable interpretation of user input, precise timing control of the transmitted signal, and the detection and reconstruction of optical signals from the received image. In this design, we design and implement an FPGA-based encrypted VLC system based on Morse code and Caesar cipher encryption. The proposed system is configured to perform the main communication processing of the transmitter on the FPGA. The user’s push-button input undergoes synchronization and debouncing, after which it is classified into dots and dashes based on the input hold time. Subsequently, the Morse code decoder converts the completed code sequence into ASCII characters; the converted characters are displayed on the LCD for user verification and simultaneously stored in the transmit buffer. During the transmission process, Caesar cipher encryption using switch-based variable keys is applied to the uppercase message stored in the buffer, and the encrypted characters are converted back into Morse code patterns. Subsequently, an LED transmitter based on a finite state machine (FSM) precisely controls the dots, dashes, spaces between symbols, and spaces between characters to transmit the encrypted Morse light signal via a green LED. The receiver is built using Python and OpenCV and detects the green LED signal by analyzing the HSV color space in the camera feed. The detected optical signal is reconstructed into dots and dashes through temporal state verification and pulse duration analysis. The reconstructed Morse code is converted into ciphertext characters and then reconstructed into the plaintext message via Caesar decryption using the same key. By combining an FPGA-based transmitter—which handles input processing, character buffering, encryption, Morse code re-encoding, and precise timing control—with a Python-based image receiver, this system presents a design for an end-to-end encrypted visible light communication system that can be implemented in a low-cost environment.



# FPGA Pin Assignments
<img width="450" height="450" alt="image" src="https://github.com/user-attachments/assets/8d80eec4-04cb-4491-b930-037b3bfd7b82" />

## Board I/O Mapping

| Signal | Direction | FPGA Pin | I/O Bank | Description |
|---|---|---:|---:|---|
| `CLOCK_50` | Input | `PIN_Y2` | 2 | 50 MHz system clock |
| `KEY[1]` | Input | `PIN_R24` | 5 | Push button input |
| `KEY[0]` | Input | `PIN_Y23` | 5 | Push button / reset input |
| `SW[10]` | Input | `PIN_AC24` | 5 | Switch input |
| `SW[9]` | Input | `PIN_AB25` | 5 | Switch input |
| `SW[8]` | Input | `PIN_AC25` | 5 | Switch input |
| `SW[7]` | Input | `PIN_AC26` | 5 | Switch input |
| `PASS` | Input | `PIN_AB28` | 5 | Password / control input |
| `LEDG[0]` | Output | `PIN_E22` | 7 | Green LED output |
| `LCD_BLON` | Output | `PIN_L6` | 1 | LCD backlight enable |
| `LCD_ON` | Output | `PIN_L5` | 1 | LCD power enable |
| `LCD_EN` | Output | `PIN_L4` | 1 | LCD enable |
| `LCD_RS` | Output | `PIN_M2` | 1 | LCD register select |
| `LCD_RW` | Output | `PIN_M1` | 1 | LCD read/write control |
| `LCD_DATA[7]` | Output | `PIN_M5` | 1 | LCD data bit 7 |
| `LCD_DATA[6]` | Output | `PIN_M3` | 1 | LCD data bit 6 |
| `LCD_DATA[5]` | Output | `PIN_K2` | 1 | LCD data bit 5 |
| `LCD_DATA[4]` | Output | `PIN_L3` | 1 | LCD data bit 4 |
| `LCD_DATA[3]` | Output | `PIN_K7` | 1 | LCD data bit 3 |
| `LCD_DATA[2]` | Output | `PIN_J1` | 1 | LCD data bit 2 |
| `LCD_DATA[1]` | Output | `PIN_L1` | 1 | LCD data bit 1 |
| `LCD_DATA[0]` | Output | `PIN_L2` | 1 | LCD data bit 0 |

## Notes

- Pin assignments are configured in `morse_top.qsf`.
- The project uses a 50 MHz input clock through `CLOCK_50`.
- LCD control and data signals are assigned to I/O Bank 1.
- Switch and key inputs are assigned to I/O Bank 5.
