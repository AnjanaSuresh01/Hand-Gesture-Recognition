import cv2
import mediapipe as mp
import numpy as np
import time
from pynput.keyboard import Controller

class RobotController:
    def __init__(self):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7
        )
        self.mp_draw = mp.solutions.drawing_utils
        
        # Initialize video capture
        self.cap = cv2.VideoCapture(0)
        
        # Get camera dimensions
        self.width = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.height = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # Define control zones
        self.left_threshold = self.width * 0.4
        self.right_threshold = self.width * 0.6
        
        # States
        self.current_command = "STOP"
        self.clamp_state = "OPEN"
        self.last_command_time = time.time()
        self.command_cooldown = 0.1  # seconds

        # Initialize keyboard controller
        self.keyboard = Controller()

    def calculate_pinch(self, landmarks):
        """Calculate if hand is pinching based on thumb and index finger distance"""
        thumb_tip = np.array([landmarks[4].x, landmarks[4].y])
        index_tip = np.array([landmarks[8].x, landmarks[8].y])
        
        distance = np.sqrt(np.sum((thumb_tip - index_tip) ** 2))
        return distance < 0.1  # Threshold for pinch detection

    def is_hand_open(self, landmarks):
        """Check if hand is fully open"""
        # Get fingertip y-positions
        finger_tips = [landmarks[i].y for i in [8, 12, 16, 20]]  # Index, Middle, Ring, Pinky
        palm_position = landmarks[0].y  # Wrist position
        
        # Check if all fingertips are above the palm
        return all(tip < palm_position for tip in finger_tips)

    def get_hand_position(self, landmarks):
        """Get the center position of the hand"""
        palm_landmark = landmarks[9]  # Middle of palm
        return (int(palm_landmark.x * self.width), int(palm_landmark.y * self.height))

    def send_keystrokes(self):
        """Send continuous keystrokes based on hand movements and clamp state"""
        # Send movement command continuously
        if self.current_command == "LEFT":
            self.keyboard.press('a')
        elif self.current_command == "RIGHT":
            self.keyboard.press('d')
        elif self.current_command == "UP":
            self.keyboard.press('w')
        elif self.current_command == "DOWN":
            self.keyboard.press('s')
        else:
            # Release all movement keys if no movement command
            self.keyboard.release('w')
            self.keyboard.release('a')
            self.keyboard.release('s')
            self.keyboard.release('d')

        # Send clamp control command with a delay for proper recognition
        if self.clamp_state == "CLOSED":
            self.keyboard.press('c')
            time.sleep(0.1)  # Small delay to ensure the key press is registered
            self.keyboard.release('c')
        elif self.clamp_state == "OPEN":
            self.keyboard.press('o')
            time.sleep(0.1)  # Small delay to ensure the key press is registered
            self.keyboard.release('o')

    def run(self):
        print("Controls:")
        print("- Move hand left/right to control robot movement")
        print("- Move hand up/down to control vertical movement")
        print("- Pinch to close clamp")
        print("- Open hand to open clamp")
        print("- Press ESC to exit")

        # Create a resizable window for the camera preview
        cv2.namedWindow('Robot Hand Control', cv2.WINDOW_NORMAL)

        while self.cap.isOpened():
            success, image = self.cap.read()
            if not success:
                continue

            # Convert image to RGB
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            results = self.hands.process(image_rgb)

            # Draw control zones
            cv2.line(image, (int(self.left_threshold), 0), 
                    (int(self.left_threshold), self.height), (0, 255, 0), 2)
            cv2.line(image, (int(self.right_threshold), 0), 
                    (int(self.right_threshold), self.height), (0, 255, 0), 2)

            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    # Draw hand landmarks
                    self.mp_draw.draw_landmarks(
                        image, hand_landmarks, self.mp_hands.HAND_CONNECTIONS)
                    
                    # Get hand position
                    hand_x, hand_y = self.get_hand_position(hand_landmarks.landmark)
                    
                    # Determine movement command based on position
                    if hand_x < self.left_threshold:
                        self.current_command = "LEFT"
                    elif hand_x > self.right_threshold:
                        self.current_command = "RIGHT"
                    elif hand_y < self.height * 0.4:
                        self.current_command = "UP"
                    elif hand_y > self.height * 0.6:
                        self.current_command = "DOWN"
                    else:
                        self.current_command = "STOP"
                    
                    # Check clamp control independently from movement
                    if self.calculate_pinch(hand_landmarks.landmark):
                        self.clamp_state = "CLOSED"
                    elif self.is_hand_open(hand_landmarks.landmark):
                        self.clamp_state = "OPEN"
                    
                    # Send keystrokes for movement and clamp control
                    self.send_keystrokes()

            # Display commands
            cv2.putText(image, f"Movement: {self.current_command}", (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(image, f"Clamp: {self.clamp_state}", (10, 70),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            # Show image with the ability to resize the window
            cv2.imshow('Robot Hand Control', image)
            
            # Exit on ESC
            if cv2.waitKey(5) & 0xFF == 27:
                break

        self.cap.release()
        cv2.destroyAllWindows()

# Usage
if __name__ == "__main__":
    controller = RobotController()
    controller.run()
