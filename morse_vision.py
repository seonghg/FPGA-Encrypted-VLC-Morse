import cv2
import numpy as np
import time

# Morse dictionary
MORSE_CODE_DICT = {
    '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
    '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
    '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
    '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
    '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
    '--..': 'Z'
}

# Timing thresholds
DOT_DASH_THRESHOLD = 0.40
CHAR_GAP_THRESHOLD = 0.45
MIN_ON_PULSE_TIME = 0.06
STATE_CONFIRM_TIME = 0.03

# HSV bounds for long-distance green LED
LOWER_GREEN = np.array([40, 80, 80])
UPPER_GREEN = np.array([90, 255, 255])

GREEN_ON_THRESHOLD = 3
GREEN_OFF_THRESHOLD = 0

ROI = None

# Decryption key (Matches FPGA SW[10:7])
SECRET_KEY = 12 # 1100

def decrypt_char(cipher_char, key):
    if cipher_char == '?':
        return '?'
    shift = key % 26
    dec_offset = (ord(cipher_char) - ord('A') - shift) % 26
    return chr(ord('A') + dec_offset)

# Extract green pixels and target bounding box
def get_led_data(frame):
    if ROI is not None:
        x, y, w, h = ROI
        target_frame = frame[y:y + h, x:x + w]
    else:
        target_frame = frame

    hsv = cv2.cvtColor(target_frame, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv, LOWER_GREEN, UPPER_GREEN)

    # Point-source tracking via dilation
    kernel = np.ones((5, 5), np.uint8)
    mask = cv2.dilate(mask, kernel, iterations=2) 

    pixel_count = cv2.countNonZero(mask)

    target_box = None
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        largest_contour = max(contours, key=cv2.contourArea)
        target_box = cv2.boundingRect(largest_contour) 

    return pixel_count, target_box

# Decode morse and decrypt cipher
def finalize_letter(current_symbol, decoded_message):
    if current_symbol == "":
        return current_symbol, decoded_message
        
    cipher_letter = MORSE_CODE_DICT.get(current_symbol, "?")
    plain_letter = decrypt_char(cipher_letter, SECRET_KEY)
    
    decoded_message += plain_letter
    print(f"Decoded: {current_symbol:5s} -> RX({cipher_letter}) -> Plain({plain_letter})")
    
    return "", decoded_message

# Camera initialization
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
if not cap.isOpened():
    cap = cv2.VideoCapture(0)
if not cap.isOpened():
    raise RuntimeError("Cannot open camera.")

cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
cap.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0.25)
cap.set(cv2.CAP_PROP_EXPOSURE, -6)
cap.set(cv2.CAP_PROP_AUTO_WB, 0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

# State variables
stable_on = False
pending_state = False
pending_state_since = time.perf_counter()
last_stable_change_time = time.perf_counter()
current_symbol = ""
decoded_message = ""

print("--- Morse Vision Decoder Started ---")
print(f"Current Key: {SECRET_KEY}")
print("------------------------------------")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    now = time.perf_counter()

    green_pixel_count, target_box = get_led_data(frame)

    if stable_on:
        raw_on = green_pixel_count > GREEN_OFF_THRESHOLD
    else:
        raw_on = green_pixel_count > GREEN_ON_THRESHOLD

    if raw_on != pending_state:
        pending_state = raw_on
        pending_state_since = now

    if (pending_state != stable_on and (now - pending_state_since) >= STATE_CONFIRM_TIME):
        previous_state_duration = now - last_stable_change_time

        if stable_on and not pending_state:
            on_duration = previous_state_duration
            if on_duration >= MIN_ON_PULSE_TIME:
                if on_duration <= DOT_DASH_THRESHOLD:
                    current_symbol += "."
                    print(f"[ON] {on_duration:.3f}s -> dot(.) | {current_symbol}")
                else:
                    current_symbol += "-"
                    print(f"[ON] {on_duration:.3f}s -> dash(-) | {current_symbol}")

        elif not stable_on and pending_state:
            off_duration = previous_state_duration
            print(f"[OFF] {off_duration:.3f}s")
            if current_symbol != "" and off_duration >= CHAR_GAP_THRESHOLD:
                current_symbol, decoded_message = finalize_letter(current_symbol, decoded_message)

        stable_on = pending_state
        last_stable_change_time = now

    if not stable_on and current_symbol != "":
        off_duration = now - last_stable_change_time
        if off_duration >= CHAR_GAP_THRESHOLD:
            current_symbol, decoded_message = finalize_letter(current_symbol, decoded_message)

    h, w, _ = frame.shape
    border_color = (0, 255, 0) if stable_on else (0, 0, 255)
    led_status = "ON" if stable_on else "OFF"
    
    cv2.rectangle(frame, (0, 0), (w - 1, h - 1), border_color, 8)

    if stable_on and target_box is not None:
        tx, ty, tw, th = target_box
        padding = 20 
        cv2.rectangle(frame, (tx - padding, ty - padding), (tx + tw + padding, ty + th + padding), (0, 255, 0), 2)
        cv2.putText(frame, "LOCK-ON", (tx - padding, ty - padding - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    cv2.putText(frame, f"LED: {led_status}", (10, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
    cv2.putText(frame, f"Key: {SECRET_KEY}", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 200, 255), 2)
    cv2.putText(frame, f"Morse: {current_symbol}", (10, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
    cv2.putText(frame, f"Message: {decoded_message}", (10, 155), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 3)

    display_frame = cv2.resize(frame, (640, 360))
    cv2.imshow("Morse Code Vision Decoder (Encrypted)", display_frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
        break
    elif key == ord("c"):
        current_symbol = ""
        decoded_message = ""
        print("\nMessage cleared.\n")

cap.release()
cv2.destroyAllWindows()