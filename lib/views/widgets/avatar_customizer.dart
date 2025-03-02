import 'package:flutter/material.dart';
import 'package:life_quest/constants/app_colors.dart';

class AvatarCustomizer extends StatefulWidget {
  final String? initialAvatarUrl;
  final Function(String) onAvatarChanged;

  const AvatarCustomizer({
    Key? key,
    this.initialAvatarUrl,
    required this.onAvatarChanged,
  }) : super(key: key);

  @override
  State<AvatarCustomizer> createState() => _AvatarCustomizerState();
}

class _AvatarCustomizerState extends State<AvatarCustomizer> {
  late Color _selectedColor;
  late String _selectedFace;
  late String _selectedHair;
  late String _selectedAccessory;

  // Sample options for customization
  final List<Color> _colorOptions = [
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.purple.shade400,
    Colors.orange.shade400,
    Colors.pink.shade400,
    Colors.teal.shade400,
  ];

  final List<String> _faceOptions = [
    'happy',
    'smile',
    'laugh',
    'cool',
    'wink',
  ];

  final List<String> _hairOptions = [
    'short',
    'long',
    'curly',
    'mohawk',
    'bald',
  ];

  final List<String> _accessoryOptions = [
    'none',
    'glasses',
    'hat',
    'earrings',
    'crown',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with default values or from provided URL
    _selectedColor = _colorOptions[0];
    _selectedFace = _faceOptions[0];
    _selectedHair = _hairOptions[0];
    _selectedAccessory = _accessoryOptions[0];

    // TODO: Parse initialAvatarUrl to set initial selections
  }

  void _updateAvatar() {
    // Generate a URL or string representation of the avatar
    // This is just a placeholder - in a real app you would generate
    // an actual avatar image or reference
    final avatarString = 'avatar:${_selectedColor.value}:${_selectedFace}:${_selectedHair}:${_selectedAccessory}';
    widget.onAvatarChanged(avatarString);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar preview
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _selectedColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedColor,
              width: 4,
            ),
          ),
          child: const Center(
            child: Text(
              '😀',
              style: TextStyle(
                fontSize: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Color selection
        _buildCustomizationSection('Color', _buildColorOptions()),

        // Face selection
        _buildCustomizationSection('Face', _buildOptionList(
          _faceOptions,
          _selectedFace,
              (value) => setState(() {
            _selectedFace = value;
            _updateAvatar();
          }),
        )),

        // Hair selection
        _buildCustomizationSection('Hair', _buildOptionList(
          _hairOptions,
          _selectedHair,
              (value) => setState(() {
            _selectedHair = value;
            _updateAvatar();
          }),
        )),

        // Accessory selection
        _buildCustomizationSection('Accessory', _buildOptionList(
          _accessoryOptions,
          _selectedAccessory,
              (value) => setState(() {
            _selectedAccessory = value;
            _updateAvatar();
          }),
        )),
      ],
    );
  }

  Widget _buildCustomizationSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildColorOptions() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colorOptions.length,
        itemBuilder: (context, index) {
          final color = _colorOptions[index];
          final isSelected = color == _selectedColor;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
                _updateAvatar();
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
              )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionList(
      List<String> options,
      String selectedOption,
      Function(String) onSelected,
      ) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selectedOption;

          return GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                ),
              ),
              child: Text(
                option.substring(0, 1).toUpperCase() + option.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.mediumText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}