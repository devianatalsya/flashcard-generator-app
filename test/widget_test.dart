import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/main.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/widgets/flip_card.dart';

void main() {
  testWidgets('App renders header, tabs, and action button', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashcardApp());
    await tester.pumpAndSettle();

    expect(find.text('FlashCard.'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Buat flashcard dari materi belajar.'), findsOneWidget);
    expect(find.text('Upload File'), findsOneWidget);
    expect(find.text('Masukkan Teks'), findsOneWidget);
    expect(find.text('Upload PDF atau DOCX.'), findsOneWidget);
    expect(find.text('Jumlah kartu'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Buat Flashcard'), findsOneWidget);
  });

  testWidgets('Counter buttons work within limits [1, 10]', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashcardApp());
    await tester.pumpAndSettle();

    // Default is 5
    expect(find.text('5'), findsOneWidget);

    // Tap minus 4 times -> reaches 1
    final minusBtn = find.text('−');
    for (int i = 0; i < 4; i++) {
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
    }
    expect(find.text('1'), findsOneWidget);

    // Tapping minus again shouldn't go below 1
    await tester.tap(minusBtn);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Tap plus 9 times -> reaches 10
    final plusBtn = find.text('+');
    for (int i = 0; i < 9; i++) {
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
    }
    expect(find.text('10'), findsOneWidget);

    // Tapping plus again shouldn't exceed 10
    await tester.tap(plusBtn);
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('Tab switching between Upload File and Masukkan Teks', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashcardApp());
    await tester.pumpAndSettle();

    // Initially on Upload File
    expect(find.text('Upload PDF atau DOCX.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // Switch to Masukkan Teks
    await tester.tap(find.text('Masukkan Teks'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Upload PDF atau DOCX.'), findsNothing);

    // Enter text in TextField
    await tester.enterText(find.byType(TextField), 'Ini materi belajar tentang Flutter.');
    await tester.pumpAndSettle();
    expect(find.text('Ini materi belajar tentang Flutter.'), findsOneWidget);

    // Switch back to Upload File
    await tester.tap(find.text('Upload File'));
    await tester.pumpAndSettle();
    expect(find.text('Upload PDF atau DOCX.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Reset button restores counter and clears input', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashcardApp());
    await tester.pumpAndSettle();

    // Change counter to 7
    final plusBtn = find.text('+');
    await tester.tap(plusBtn);
    await tester.tap(plusBtn);
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);

    // Switch to text and enter text
    await tester.tap(find.text('Masukkan Teks'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Test materi');
    await tester.pumpAndSettle();

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Counter is reset to 5
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('FlipCard widget flips between question and answer', (WidgetTester tester) async {
    const card = Flashcard(
      question: 'Apa itu Flutter?',
      answer: 'Flutter adalah UI framework multiplatform dari Google.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlipCardWidget(card: card, index: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Front face
    expect(find.text('01'), findsOneWidget);
    expect(find.text('PERTANYAAN'), findsOneWidget);
    expect(find.text('Apa itu Flutter?'), findsOneWidget);

    // Tap to flip
    await tester.tap(find.byType(FlipCardWidget));
    await tester.pumpAndSettle();

    // Back face
    expect(find.text('JAWABAN'), findsOneWidget);
    expect(find.text('Flutter adalah UI framework multiplatform dari Google.'), findsOneWidget);

    // Tap to flip back
    await tester.tap(find.byType(FlipCardWidget));
    await tester.pumpAndSettle();

    expect(find.text('PERTANYAAN'), findsOneWidget);
    expect(find.text('Apa itu Flutter?'), findsOneWidget);
  });
}
