import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = LanguageService();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white),
      tooltip: 'Change Language',
      onSelected: (lang) => svc.setLanguage(lang),
      itemBuilder: (_) => LanguageService.languages.entries.map((e) {
        final isSelected = svc.lang == e.key;
        return PopupMenuItem<String>(
          value: e.key,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, color: Color(0xFF2A7525), size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(e.value,
                  style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
