import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AiChatMessageRole { user, model }

class AiChatMessage {
  const AiChatMessage({
    required this.role,
    required this.text,
  });

  final AiChatMessageRole role;
  final String text;

  bool get isUser => role == AiChatMessageRole.user;
}

class AiChatController extends GetxController {
  AiChatController({FirebaseVertexAI? firebaseVertexAI})
      : _vertexAI = firebaseVertexAI ?? FirebaseVertexAI.instance;

  static const nonEducationalResponse =
      'Sorry, I’m not able to respond to that. Please ask me a question about an educational topic.';

  final FirebaseVertexAI _vertexAI;
  final TextEditingController inputController = TextEditingController();
  final RxList<AiChatMessage> messages = <AiChatMessage>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }

  Future<void> sendMessage() async {
    final question = inputController.text.trim();
    if (question.isEmpty || isLoading.value) {
      return;
    }

    inputController.clear();
    messages.add(
      AiChatMessage(role: AiChatMessageRole.user, text: question),
    );

    if (!_isEducationalQuestion(question)) {
      messages.add(
        const AiChatMessage(
          role: AiChatMessageRole.model,
          text: nonEducationalResponse,
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      final model = _vertexAI.generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: Content.text(
          'You are an educational assistant supporting students, parents, and teachers. '
          'Answer clearly and concisely while focusing only on academic topics such as math, science, history, or computer science.',
        ),
      );

      final response = await model.generateContent([
        Content.text(question),
      ]);

      final answer = response.text?.trim();
      if (answer != null && answer.isNotEmpty) {
        messages.add(
          AiChatMessage(role: AiChatMessageRole.model, text: answer),
        );
      } else {
        messages.add(
          const AiChatMessage(
            role: AiChatMessageRole.model,
            text:
                'I was unable to generate a response right now. Please try asking your question again.',
          ),
        );
      }
    } catch (_) {
      messages.add(
        const AiChatMessage(
          role: AiChatMessageRole.model,
          text:
              'Something went wrong while connecting to Gemini. Please try again later.',
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _isEducationalQuestion(String input) {
    final text = input.toLowerCase();

    const allowedKeywords = [
      'math',
      'mathematics',
      'algebra',
      'geometry',
      'calculus',
      'statistics',
      'probability',
      'equation',
      'theorem',
      'pythagorean theorem',
      'fraction',
      'science',
      'scientific',
      'physics',
      'chemistry',
      'biology',
      'geology',
      'astronomy',
      'ecosystem',
      'photosynthesis',
      'cell division',
      'energy',
      'matter',
      'experiment',
      'history',
      'historical',
      'ancient',
      'civilization',
      'revolution',
      'french revolution',
      'industrial revolution',
      'renaissance',
      'world war',
      'world war i',
      'world war 1',
      'world war ii',
      'world war 2',
      'wwi',
      'ww1',
      'wwii',
      'ww2',
      'cold war',
      'napoleon',
      'empire',
      'timeline',
      'computer science',
      'programming',
      'programming language',
      'coding',
      'software',
      'software engineering',
      'algorithm',
      'data structure',
      'data science',
      'database',
      'networking',
      'binary search',
      'recursion',
      'machine learning',
      'artificial intelligence',
    ];

    for (final keyword in allowedKeywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }

    if (RegExp(r'\d').hasMatch(text) && RegExp(r'[=+\-*/^]').hasMatch(text)) {
      return true;
    }

    if (RegExp(r'\bwho (is|was)\b').hasMatch(text) &&
        RegExp(
          r'\b(king|queen|emperor|pharaoh|scientist|inventor|histor|mathematician|physicist|chemist|biologist|programmer|computer|general|leader)\b',
        ).hasMatch(text)) {
      return true;
    }

    final normalized = text.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.length <= 1) {
      return false;
    }

    const mathTerms = {
      'math',
      'mathematics',
      'algebra',
      'geometry',
      'calculus',
      'statistics',
      'probability',
      'equation',
      'theorem',
      'fraction',
      'integral',
      'derivative',
      'matrix',
      'vector',
      'algebraic',
    };
    const scienceTerms = {
      'science',
      'physics',
      'chemistry',
      'biology',
      'geology',
      'astronomy',
      'ecosystem',
      'cell',
      'atom',
      'molecule',
      'gravity',
      'force',
      'element',
      'reaction',
    };
    const historyTerms = {
      'history',
      'historical',
      'ancient',
      'civilization',
      'revolution',
      'war',
      'empire',
      'timeline',
      'king',
      'queen',
      'battle',
      'dynasty',
      'treaty',
      'colonial',
    };
    const csTerms = {
      'computer',
      'computing',
      'programming',
      'coding',
      'software',
      'hardware',
      'algorithm',
      'data',
      'database',
      'network',
      'binary',
      'debug',
      'python',
      'java',
      'c++',
      'javascript',
      'variable',
      'loop',
      'array',
      'recursion',
      'compiler',
    };

    var subjectHits = 0;
    for (final token in tokens) {
      if (mathTerms.contains(token) ||
          scienceTerms.contains(token) ||
          historyTerms.contains(token) ||
          csTerms.contains(token)) {
        subjectHits++;
      }
      if (subjectHits >= 2) {
        return true;
      }
    }

    return false;
  }
}
