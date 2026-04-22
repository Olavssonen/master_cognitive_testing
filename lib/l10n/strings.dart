/// Abstract interface for all app strings
/// Each concrete implementation provides translations for a specific locale
abstract class AppStrings {
  // App
  String get appTitle;
  String get play;
  String get exit;
  String get exitConfirm;
  String get back;
  String get confirm;

  // Screen titles
  String get settings;
  String get selectTests;
  String get summary;

  // Settings labels
  String get language;
  String get debug;
  String get points;

  // Button labels
  String get start;
  String get stop;
  String get done;
  String get cancel;
  String get clear;
  String get next;
  String get beginTest;
  String get skip;

  // Test names
  String get counterTest;
  String get tap10Test;
  String get cogTest;
  String get tmtTest;
  String get stroopTest;

  // Test instructions & labels
  String get round1;
  String get round2;
  String get round3;
  String get round4;
  String get clockInstruction;
  String get clockInstruction2;
  String get lookAtColorNotWord;
  String get clockDrawPosition;
  String get clockHandInstruction;
  String get clockGoalTime;
  String get memory;
  String get rememberWords;
  String get repeatWords;
  String get numbersCircles;
  String get lettersCircles;
  String get mixedCircles;
  String get numbers;
  String get mixed;

  // Tutorial screens
  String get howToPlay;
  String get counterTutorialDesc;
  String get tap10TutorialDesc;
  String get currentCount;
  String get tapsLabel;
  String get tapsRemaining;
  String get tutorialComplete;
  String get readyToContinue;
  String get retry;
  String get great;
  String get gotIt;
  String get continueTutorial;
  String get tap10TapsToGo;
  String get correctLabel;
  String get wrongLabel;
  String get correct_correct;
  String get wrong_label;
  String get accuracy_label;
  String get mistakes;
  String get circles;
  String get noDrawingsFound;
  String get numberStage;
  String get letterStage;
  String get miniCogScore;
  String get wordRecall;
  String get clockNumbers;
  String get hourHand;
  String get minuteHand;
  String get clockHands;
  String get clockDrawing;
  String get miniCogCardTitle;
  String get wordsRemembered;
  String get totalScoreLabel;

  // COG Test - Words to remember
  String get bananWord;
  String get sunriseWord;
  String get chairWord;

  // COG Test - Distractor words
  String get leatherWord;
  String get seasonWord;
  String get tableWord;
  String get villageWord;
  String get kitchenWord;
  String get babyWord;
  String get riverWord;

  // Results & feedback
  String get testComplete;
  String get testsCompleted;
  String get correct;
  String get wrong;
  String get accuracy;
  String get taps;
  String get time;
  String get completed;
  String get incomplete;
  String get errorMessage;

  // Stroop Test V2 - Color words and UI
  String get hereIsAnExample;
  String get correctOption;
  String get wrongOption;
  String get colorRed;
  String get colorBlue;
  String get colorGreen;
  String get colorYellow;
}
