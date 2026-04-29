import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({Key? key}) : super(key: key);

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedDifficulty = 'Orta';
  double _hoursAllocated = 2.0;
  bool _isLoading = false;
  bool _isAiLoading = false;
  final _aiPromptController = TextEditingController();

  final List<String> _difficulties = ['Kolay', 'Orta', 'Zor'];

  void _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      // Backend Lesson model doesn't support Difficulty and Hours yet, 
      // but we send Name to satisfy the real API and simulate the rest for the UI.
      await apiService.dio.post('/Lesson', data: {
        'name': _nameController.text,
        'colorCode': '#3498db'
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan başarıyla oluşturuldu!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan oluşturulurken hata oluştu.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateAiPlan() async {
    if (_aiPromptController.text.trim().isEmpty) return;

    setState(() {
      _isAiLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.dio.post('/Ai/plan', data: {
        'prompt': _aiPromptController.text
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _nameController.text = data['suggestedName'] ?? '';
          
          final String suggestedDiff = data['suggestedDifficulty'] ?? 'Orta';
          if (_difficulties.contains(suggestedDiff)) {
            _selectedDifficulty = suggestedDiff;
          } else {
             _selectedDifficulty = 'Orta';
          }
          
          double hours = (data['recommendedHours'] ?? 2.0).toDouble();
          if (hours < 0.5) hours = 0.5;
          if (hours > 10.0) hours = 10.0;
          _hoursAllocated = hours;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Önerisi: ${data['advice']}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI planı oluşturulurken hata oluştu.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Çalışma Planı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AI Planner Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text('AI ile Otomatik Planla', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _aiPromptController,
                              decoration: InputDecoration(
                                hintText: 'Örn: Vizeye 3 gün kaldı, matematik...',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isAiLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.deepPurple, strokeWidth: 3)),
                              )
                            : IconButton(
                                onPressed: _generateAiPlan,
                                icon: const Icon(Icons.send_rounded, color: Colors.deepPurple),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),

                // Name Input
                const Text(
                  'Ders veya Konu Adı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (value) => value == null || value.isEmpty ? 'Lütfen ders adı girin' : null,
                  decoration: InputDecoration(
                    hintText: 'Örn: Matematik - Türev',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.menu_book_rounded, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),

                // Difficulty Dropdown
                const Text(
                  'Zorluk Seviyesi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDifficulty,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      items: _difficulties.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDifficulty = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Hours Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hedeflenen Süre',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    Text(
                      '${_hoursAllocated.toStringAsFixed(1)} Saat',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: Colors.blueAccent.withOpacity(0.2),
                    thumbColor: Colors.blueAccent,
                    overlayColor: Colors.blueAccent.withOpacity(0.2),
                    trackHeight: 8.0,
                  ),
                  child: Slider(
                    value: _hoursAllocated,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        _hoursAllocated = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Planı Oluştur',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
