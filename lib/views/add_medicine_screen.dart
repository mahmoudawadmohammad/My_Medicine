// ============================================================
// ملف: add_medicine_screen.dart
// المسار: lib/views/add_medicine/add_medicine_screen.dart
// الوصف: صفحة إضافة دواء - تصنيف اختياري بدل الدرج
// ============================================================

// 📦 استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../controllers/medicine_controller.dart';
import '../../controllers/category_controller.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // ==========================================================
  // مفاتيح ومتحكمات النموذج
  // ==========================================================

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pillCountController = TextEditingController();

  // ==========================================================
  // متغيرات النموذج
  // ==========================================================

  // ✅ التصنيف المحدد (null = بدون تصنيف)
  int? _selectedCategoryId;

  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay? _selectedTime2;
  TimeOfDay? _selectedTime3;

  // ==========================================================
  // متغيرات أيام الأسبوع
  // ==========================================================

  final List<Map<String, dynamic>> _weekDays = [
    {'name': 'saturday'.tr,     'short': 'sat_short'.tr, 'value': 1, 'isSelected': false},
    {'name': 'sunday'.tr,     'short': 'sun_short'.tr, 'value': 2, 'isSelected': false},
    {'name': 'monday'.tr,   'short': 'mon_short'.tr, 'value': 3, 'isSelected': false},
    {'name': 'tuesday'.tr,  'short': 'tue_short'.tr, 'value': 4, 'isSelected': false},
    {'name': 'wednesday'.tr,  'short': 'wed_short'.tr, 'value': 5, 'isSelected': false},
    {'name': 'thursday'.tr,    'short': 'thu_short'.tr, 'value': 6, 'isSelected': false},
    {'name': 'friday'.tr,    'short': 'fri_short'.tr, 'value': 7, 'isSelected': false},
  ];
  bool _isAllDaysSelected = false;

  // ==========================================================
  // المتحكمات
  // ==========================================================

  final MedicineController _medicineController = Get.find<MedicineController>();
  final CategoryController _categoryController = Get.find<CategoryController>();

  // ==========================================================
  // دورة الحياة
  // ==========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _pillCountController.dispose();
    super.dispose();
  }

  // ==========================================================
  // بناء الواجهة
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      // ===== شريط التطبيق =====
      appBar: AppBar(
        title: Text(
          'add_medicine'.tr,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ===== جسم الصفحة =====
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.1),
                surfaceColor,
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== أيقونة في الأعلى =====
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // 1️⃣ حقل اسم الدواء
                  // ==========================================
                  _buildSectionTitle('medicine_name'.tr),
                  const SizedBox(height: 8),
                  _buildNameField(),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 2️⃣ حقل عدد الحبات
                  // ==========================================
                  _buildSectionTitle('pill_count'.tr),
                  const SizedBox(height: 8),
                  _buildPillCountField(),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 3️⃣ ✅ اختيار التصنيف (اختياري)
                  // ==========================================
                  _buildSectionTitle('category_optional'.tr),
                  const SizedBox(height: 8),
                  _buildCategorySelector(),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 4️⃣ اختيار أيام الأسبوع
                  // ==========================================
                  _buildSectionTitle('days_title'.tr),
                  const SizedBox(height: 8),
                  _buildWeekDaysSelector(),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 5️⃣ اختيار الوقت الأول
                  // ==========================================
                  _buildSectionTitle('dose_time'.tr),
                  const SizedBox(height: 8),
                  _buildTimeSelector(
                    selectedTime: _selectedTime,
                    onTimePicked: (time) => setState(() => _selectedTime = time),
                    label: 'first_dose'.tr,
                  ),

                  const SizedBox(height: 12),

                  // ==========================================
                  // 6️⃣ الوقت الثاني (اختياري)
                  // ==========================================
                  if (_selectedTime2 == null)
                    _buildAddTimeButton(
                      label: 'second_dose_time'.tr,
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await Future.delayed(const Duration(milliseconds: 100));
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          initialEntryMode: TimePickerEntryMode.dialOnly,
                        );
                        if (picked != null) setState(() => _selectedTime2 = picked);
                      },
                    )
                  else
                    _buildTimeSelector(
                      selectedTime: _selectedTime2!,
                      onTimePicked: (time) => setState(() => _selectedTime2 = time),
                      label: 'second_dose'.tr,
                      onRemove: () => setState(() => _selectedTime2 = null),
                    ),

                  const SizedBox(height: 8),

                  // ==========================================
                  // 7️⃣ الوقت الثالث (اختياري)
                  // ==========================================
                  if (_selectedTime3 == null)
                    _buildAddTimeButton(
                      label: 'third_dose_time'.tr,
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await Future.delayed(const Duration(milliseconds: 100));
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          initialEntryMode: TimePickerEntryMode.dialOnly,
                        );
                        if (picked != null) setState(() => _selectedTime3 = picked);
                      },
                    )
                  else
                    _buildTimeSelector(
                      selectedTime: _selectedTime3!,
                      onTimePicked: (time) => setState(() => _selectedTime3 = time),
                      label: 'third_dose'.tr,
                      onRemove: () => setState(() => _selectedTime3 = null),
                    ),

                  const SizedBox(height: 40),

                  // ==========================================
                  // 8️⃣ ملخص الإضافة
                  // ==========================================
                  _buildSummary(),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 9️⃣ زر الحفظ
                  // ==========================================
                  ElevatedButton(
                    onPressed: _saveMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'save_medicine'.tr,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.save_alt),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // عنوان القسم
  // ==========================================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // ==========================================================
  // حقل اسم الدواء
  // ==========================================================
  Widget _buildNameField() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'medicine_name'.tr,
          hintText: 'name_hint'.tr,
          prefixIcon: Icon(Icons.medication, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: surfaceColor,
          labelStyle: GoogleFonts.cairo(),
          hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
        ),
        style: GoogleFonts.cairo(fontSize: 16),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'name_required'.tr;
          }
          return null;
        },
      ),
    );
  }

  // ==========================================================
  // حقل عدد الحبات
  // ==========================================================
  Widget _buildPillCountField() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.remove, color: primaryColor),
                  onPressed: () {
                    int currentValue = int.tryParse(_pillCountController.text) ?? 1;
                    if (currentValue > 1) {
                      _pillCountController.text = (currentValue - 1).toString();
                    }
                  },
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _pillCountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    labelText: 'pill_count_label'.tr,
                    hintText: 'pill_count_hint'.tr,
                    prefixIcon: Icon(Icons.numbers, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    labelStyle: GoogleFonts.cairo(),
                    hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
                  ),
                  style: GoogleFonts.cairo(fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'pill_count_required'.tr;
                    }
                    final count = int.tryParse(value);
                    if (count == null) return 'invalid_number'.tr;
                    if (count < 1) return 'pill_count_invalid'.tr;
                    if (count > 100) return 'max_pills'.tr;
                    return null;
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: primaryColor),
                  onPressed: () {
                    int currentValue = int.tryParse(_pillCountController.text) ?? 0;
                    if (currentValue < 100) {
                      _pillCountController.text = (currentValue + 1).toString();
                    }
                  },
                ),
              ),
            ],
          ),
          _buildPillCountVisualizer(),
        ],
      ),
    );
  }

  // ==========================================================
  // عرض بصري لعدد الحبات
  // ==========================================================
  Widget _buildPillCountVisualizer() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _pillCountController,
      builder: (context, value, child) {
        final count = int.tryParse(value.text) ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (count / 100).clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getPillCountColor(count)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
                  Text(
                    _getPillCountMessage(count),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getPillCountColor(count),
                    ),
                  ),
                  Text('100+', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // ✅ محدد التصنيف (اختياري)
  // ==========================================================
  Widget _buildCategorySelector() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Obx(() {
      final categories = _categoryController.categories;

      return Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // ----- خيار "بدون تصنيف" -----
            RadioListTile<int?>(
              value: null,
              groupValue: _selectedCategoryId,
              activeColor: primaryColor,
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.remove, color: Colors.grey, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'no_category'.tr,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              onChanged: (value) {
                setState(() => _selectedCategoryId = null);
              },
            ),

            // ----- التصنيفات المتاحة -----
            ...categories.map((category) {
              return RadioListTile<int?>(
                value: category.id,
                groupValue: _selectedCategoryId,
                activeColor: category.color,
                title: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: category.color.withOpacity(0.2),
                      ),
                      child: Icon(category.icon, color: category.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.name,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              );
            }).toList(),

            // ----- إذا لا توجد تصنيفات -----
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'no_categories_yet'.tr,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    });
  }

  // ==========================================================
  // محدد أيام الأسبوع
  // ==========================================================
  Widget _buildWeekDaysSelector() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('all_days'.tr, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            subtitle: Text('every_day'.tr, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[600])),
            value: _isAllDaysSelected,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                _isAllDaysSelected = value;
                for (var day in _weekDays) {
                  day['isSelected'] = value;
                }
              });
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(children: _buildDayButtonsRow(0, 4)),
                const SizedBox(height: 12),
                Row(children: _buildDayButtonsRow(4, 7)),
              ],
            ),
          ),
          if (_weekDays.any((d) => d['isSelected'] as bool) && !_isAllDaysSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${'days_selected'.tr} ${_getSelectedDaysText()}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // صف أزرار الأيام
  // ==========================================================
  List<Widget> _buildDayButtonsRow(int startIndex, int endIndex) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final days = _weekDays.sublist(startIndex, endIndex);
    final count = days.length;

    return List.generate(count, (index) {
      final day = days[index];
      final isSelected = day['isSelected'] as bool;
      final dayShort = day['short'] as String;

      Widget dayButton = GestureDetector(
        onTap: () {
          setState(() {
            day['isSelected'] = !isSelected;
            _isAllDaysSelected = _weekDays.every((d) => d['isSelected'] as bool);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(height: 4),
              Text(
                dayShort,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );

      if (count > 1) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == 0 ? 0 : 6,
              left: index == count - 1 ? 0 : 6,
            ),
            child: dayButton,
          ),
        );
      } else {
        return SizedBox(width: 100, child: dayButton);
      }
    });
  }

  // ==========================================================
  // نص الأيام المختارة
  // ==========================================================
  String _getSelectedDaysText() {
    final selectedDays = _weekDays.where((d) => d['isSelected'] as bool).toList();
    final names = selectedDays.map((d) => d['name'] as String).toList();
    return names.join('، ');
  }

  // ==========================================================
  // محدد الوقت
  // ==========================================================
  Widget _buildTimeSelector({
    required TimeOfDay selectedTime,
    required Function(TimeOfDay) onTimePicked,
    required String label,
    VoidCallback? onRemove,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.access_time, color: primaryColor),
        ),
        title: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w500)),
        subtitle: Text(
          selectedTime.format(context),
          style: GoogleFonts.cairo(
            fontSize: 20,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () async {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 100));
          final picked = await showTimePicker(
            context: context,
            initialTime: selectedTime,
            initialEntryMode: TimePickerEntryMode.dialOnly,
          );
          if (picked != null) onTimePicked(picked);
        },
      ),
    );
  }

  // ==========================================================
  // زر إضافة وقت جديد
  // ==========================================================
  Widget _buildAddTimeButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add, color: primaryColor),
        ),
        title: Text(
          label,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w500, color: primaryColor),
        ),
        trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
        onTap: onPressed,
      ),
    );
  }

  // ==========================================================
  // ملخص الإضافة
  // ==========================================================
  Widget _buildSummary() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _pillCountController,
      builder: (context, pillValue, child) {
        final pillCount = int.tryParse(pillValue.text) ?? 0;
        final name = _nameController.text.trim().isEmpty ? '---' : _nameController.text.trim();

        // ✅ اسم التصنيف
        final category = _categoryController.getCategoryById(_selectedCategoryId);
        final categoryName = category?.name ?? 'no_category'.tr;

        // ✅ نص الأوقات
        String timesText = _selectedTime.format(context);
        if (_selectedTime2 != null) timesText += ', ${_selectedTime2!.format(context)}';
        if (_selectedTime3 != null) timesText += ', ${_selectedTime3!.format(context)}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'summary_title'.tr,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('summary_medicine'.tr, name),
              _buildSummaryRow('summary_pills'.tr, '$pillCount ${'pill'.tr}'),
              _buildSummaryRow('summary_category'.tr, categoryName),
              _buildSummaryRow('summary_days'.tr,
                  _isAllDaysSelected ? 'all_days'.tr : _getSelectedDaysText()),
              _buildSummaryRow('summary_time'.tr, timesText),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(':', style: GoogleFonts.cairo(color: Colors.grey[600])),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onSurfaceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // دوال مساعدة للألوان والرسائل
  // ==========================================================
  Color _getPillCountColor(int count) {
    if (count == 0) return Colors.red;
    if (count <= 5) return Colors.orange;
    if (count <= 10) return Colors.amber;
    return Theme.of(context).colorScheme.primary;
  }

  String _getPillCountMessage(int count) {
    if (count == 0) return 'no_pills_entered'.tr;
    if (count == 1) return 'only_one_pill'.tr;
    if (count <= 3) return '${'low_count'.tr} ($count ${'pills'.tr})';
    if (count <= 10) return '${'medium_amount'.tr} ($count ${'pills'.tr})';
    if (count <= 30) return '${'good_amount'.tr} ($count ${'pill'.tr})';
    return '${'abundant_amount'.tr} ($count ${'pill'.tr})';
  }

  // ==========================================================
  // ✅ دالة حفظ الدواء
  // ==========================================================
  Future<void> _saveMedicine() async {
    // 1️⃣ التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) return;

    // 2️⃣ التحقق من اختيار يوم واحد على الأقل
    final selectedDaysCount = _weekDays.where((d) => d['isSelected'] as bool).length;
    if (selectedDaysCount == 0 && !_isAllDaysSelected) {
      Get.snackbar(
        'error'.tr,
        'select_day'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 3️⃣ قراءة عدد الحبات
    final pillCount = int.tryParse(_pillCountController.text.trim()) ?? 0;

    if (pillCount < 1) {
      Get.snackbar(
        'error'.tr,
        'pill_count_invalid'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 4️⃣ جمع الأيام المختارة
    final List<int> selectedDays = _isAllDaysSelected
        ? []
        : _weekDays
        .where((d) => d['isSelected'] as bool)
        .map((d) => d['value'] as int)
        .toList();

    // 5️⃣ إنشاء كائن Medicine جديد
    final medicine = Medicine(
      name: _nameController.text.trim(),
      pillCount: pillCount,
      categoryId: _selectedCategoryId, // ✅ التصنيف الاختياري
      time: _selectedTime,
      time2: _selectedTime2,
      time3: _selectedTime3,
      isActive: true,
      lastRefillDate: DateTime.now(),
      selectedDays: selectedDays,
    );

    // 6️⃣ إضافة الدواء
    final success = await _medicineController.addMedicine(medicine);

    // 7️⃣ العودة للصفحة السابقة
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}