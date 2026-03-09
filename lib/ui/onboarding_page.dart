import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/interactive_widgets.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingPage({
    super.key,
    required this.onFinished,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  String? _selectedPersonType;
  String? _selectedFrequency;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishFlow() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedPersonType != null) {
      await prefs.setString('user_person_type', _selectedPersonType!);
    }
    if (_selectedFrequency != null) {
      await prefs.setString('user_income_frequency', _selectedFrequency!);
    }
    if (_amountController.text.isNotEmpty) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      await prefs.setDouble('user_income_amount', amount);
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (_pageController.page != null && _pageController.page! > 0) {
              _prevPage();
            }
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: [
              _buildScreen1(theme),
              _buildScreen2(theme),
              _buildScreen3(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen1(ThemeData theme) {
    final choices = [
      'Student',
      'Working',
      'Freelancer',
      'Out of School Youth',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Before we start, let me get to know you!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What best describes you right now?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: choices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final choice = choices[index];
              final isSelected = _selectedPersonType == choice;
              return _SelectionCard(
                text: choice,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedPersonType = choice;
                  });
                  // Auto advance logic or give a brief delay
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (mounted) _nextPage();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScreen2(ThemeData theme) {
    final frequencies = [
      'Daily',
      'Weekly',
      'Monthly',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How do you usually receive your money?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: frequencies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final freq = frequencies[index];
              final isSelected = _selectedFrequency == freq;
              return _SelectionCard(
                text: freq,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFrequency = freq;
                  });
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (mounted) _nextPage();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScreen3(ThemeData theme) {
    String subtitle = 'How much do you receive?';
    if (_selectedFrequency == 'Daily') {
      subtitle = 'How much is your daily allowance or budget?';
    } else if (_selectedFrequency == 'Weekly') {
      subtitle = 'How much do you receive every week?';
    } else if (_selectedFrequency == 'Monthly') {
      subtitle = 'How much do you receive every month?';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How much do you usually receive?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            prefixText: '₱ ',
            prefixStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            hintText: '0.00',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          onChanged: (val) {
            setState(() {}); // enable/disable button
          },
        ),
        const SizedBox(height: 16),
        Text(
          'This helps us set up your experience. You can update this anytime.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: InteractiveButton(
            isPrimary: _amountController.text.isNotEmpty,
            onTap: _amountController.text.isNotEmpty ? () { _finishFlow(); } : null,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _amountController.text.isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Let's Go!",
                style: TextStyle(
                  color: _amountController.text.isNotEmpty
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InteractiveButton(
      onTap: onTap,
      isPrimary: isSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
