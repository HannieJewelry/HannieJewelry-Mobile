import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

// Định dạng tự động cho ngày sinh: DD/MM/YYYY
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Nếu đang xóa, cho phép xóa
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    // Chỉ cho phép nhập số
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Nếu không có gì thì trả về rỗng
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Giới hạn độ dài tối đa 8 chữ số (DDMMYYYY)
    final limitedText = newText.length > 8 ? newText.substring(0, 8) : newText;

    // Tự động thêm dấu / sau khi nhập đủ 2 chữ số cho ngày và tháng
    var formattedText = '';
    for (var i = 0; i < limitedText.length; i++) {
      // Thêm dấu / sau ngày (vị trí 2) và sau tháng (vị trí 4)
      if (i == 2 || i == 4) {
        formattedText += '/';
      }
      formattedText += limitedText[i];
    }

    // Validation cơ bản trong quá trình nhập
    if (formattedText.length >= 2) {
      final dayPart = formattedText.substring(0, 2);
      final day = int.tryParse(dayPart);
      if (day != null && (day < 1 || day > 31)) {
        // Không cho phép nhập ngày > 31
        return oldValue;
      }
    }
    
    if (formattedText.length >= 5) {
      final monthPart = formattedText.substring(3, 5);
      final month = int.tryParse(monthPart);
      if (month != null && (month < 1 || month > 12)) {
        // Không cho phép nhập tháng > 12
        return oldValue;
      }
    }

    // Tính toán vị trí con trỏ mới
    var cursorPosition = formattedText.length;
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dateOfBirthController;
  String _selectedGender = 'MALE';
  bool _isLoading = false;
  bool _showDatePickerIcon = true;
  String? _dateError; // Lưu lỗi validation ngày sinh
  
  // Biến lưu trữ ảnh avatar đã chọn
  File? _selectedAvatar;
  // ImagePicker để chọn ảnh
  final ImagePicker _picker = ImagePicker();
  // Lưu URL avatar hiện tại từ API
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _currentAvatarUrl = user?.avatarUrl;
    
    // Định dạng lại ngày sinh từ API (nếu có)
    String formattedBirthday = '';
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        // Xử lý ngày sinh từ API, đảm bảo không bị lệch ngày do múi giờ
        String apiDate = user.dateOfBirth!;
        
        // Trích xuất phần ngày tháng năm từ chuỗi ISO
        if (apiDate.contains('T')) {
          apiDate = apiDate.split('T')[0];
        }
        
        final parts = apiDate.split('-');
        if (parts.length == 3) {
          // Tạo ngày từ các thành phần để đảm bảo đúng ngày
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          
          // Định dạng lại theo DD/MM/YYYY
          formattedBirthday = '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
          
          print('🔄 EditProfileScreen: Parsed birthday from API');
          print('   Original API date: ${user.dateOfBirth}');
          print('   Extracted date part: $apiDate');
          print('   Formatted for display: $formattedBirthday');
        } else {
          // Nếu không phân tích được, thử cách khác
          final date = DateTime.parse(apiDate);
          formattedBirthday = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
      } catch (e) {
        print('⚠️ EditProfileScreen: Error parsing birthday from API: ${user.dateOfBirth}');
        print('⚠️ EditProfileScreen: Error details: $e');
        formattedBirthday = '';
      }
    }
    _dateOfBirthController = TextEditingController(text: formattedBirthday);
    
    // Theo dõi thay đổi của trường ngày sinh để hiển thị/ẩn icon và validate
    _dateOfBirthController.addListener(() {
      setState(() {
        _showDatePickerIcon = _dateOfBirthController.text.isEmpty;
        // Validate ngày sinh real-time nếu có nội dung
        if (_dateOfBirthController.text.isNotEmpty) {
          _dateError = _validateBirthDate(_dateOfBirthController.text);
        } else {
          _dateError = null;
        }
      });
    });
    
    // Convert display values to enum values
    final userGender = user?.gender ?? 'Male';
    _selectedGender = _convertToEnumGender(userGender);
  }
  
  // Convert display gender to API enum format
  String _convertToEnumGender(String displayGender) {
    switch (displayGender.toLowerCase()) {
      case 'male':
      case 'nam':
        return 'MALE';
      case 'female':
      case 'nữ':
      case 'nu':
        return 'FEMALE';
      default:
        return 'MALE';
    }
  }
  
  // Convert enum gender to display format
  String _convertToDisplayGender(String enumGender) {
    switch (enumGender) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      default:
        return 'Male';
    }
  }

  // Kiểm tra và định dạng ngày sinh
  String _formatBirthday(String birthday) {
    // Nếu trống, trả về ngày mặc định
    if (birthday.isEmpty) {
      return '2000-01-01';
    }
    
    try {
      // Kiểm tra định dạng DD-MM-YYYY hoặc YYYY-MM-DD
      final RegExp dateRegex = RegExp(r'^(\d{1,4})[-/.](\d{1,2})[-/.](\d{1,4})$');
      final match = dateRegex.firstMatch(birthday);
      
      if (match != null) {
        final part1 = int.parse(match.group(1)!);
        final part2 = int.parse(match.group(2)!);
        final part3 = int.parse(match.group(3)!);
        
        int year, month, day;
        
        // Kiểm tra xem định dạng là DD-MM-YYYY hay YYYY-MM-DD
        if (part1 > 31) {
          // YYYY-MM-DD
          year = part1;
          month = part2;
          day = part3;
        } else {
          // DD-MM-YYYY
          day = part1;
          month = part2;
          year = part3;
        }
        
        // Xử lý năm 2 chữ số
        if (year < 100) {
          year = 2000 + year;
        } else if (year < 1000) {
          year = 1900 + (year % 100);
        }
        
        // Kiểm tra tính hợp lệ của ngày tháng
        if (month < 1 || month > 12) month = 1;
        if (day < 1 || day > 31) day = 1;
        
        // Định dạng lại thành YYYY-MM-DD
        return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
      
      // Nếu không khớp với định dạng, thử parse trực tiếp
      final date = DateTime.parse(birthday);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('⚠️ EditProfileScreen: Invalid birthday format: $birthday');
      print('⚠️ EditProfileScreen: Error: $e');
      return '2000-01-01';  // Trả về ngày mặc định nếu không thể parse
    }
  }

  // Chọn ngày từ DatePicker
  Future<void> _selectDate(BuildContext context) async {
    // LUÔN lấy thời gian hiện tại động cho DatePicker
    final currentDate = DateTime.now();
    
    DateTime initialDate;
    try {
      // Thử parse ngày hiện tại từ định dạng DD/MM/YYYY, nếu không được thì dùng ngày mặc định
      if (_dateOfBirthController.text.isNotEmpty) {
        final parts = _dateOfBirthController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]), // năm
            int.parse(parts[1]), // tháng
            int.parse(parts[0]), // ngày
          );
        } else {
          // Mặc định là 18 tuổi từ thời gian hiện tại
          initialDate = currentDate.subtract(const Duration(days: 365 * 18));
        }
      } else {
        // Mặc định là 18 tuổi từ thời gian hiện tại
        initialDate = currentDate.subtract(const Duration(days: 365 * 18));
      }
    } catch (e) {
      // Mặc định là 18 tuổi từ thời gian hiện tại
      initialDate = currentDate.subtract(const Duration(days: 365 * 18));
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: currentDate, // Sử dụng thời gian hiện tại động
      // Force calendar mode only - BỎ cây bút chì edit icon
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
            // Ẩn hoàn toàn edit button
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
            ),
          ),
          child: child!,
        );
      },
      // Thêm các text tiếng Việt
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    
    if (picked != null) {
      setState(() {
        // Định dạng ngày theo DD/MM/YYYY cho hiển thị
        _dateOfBirthController.text = 
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // Convert YYYY-MM-DD to DD/MM/YYYY for display
  String _formatDisplayDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  // Kiểm tra năm nhuận
  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
  
  // Lấy số ngày tối đa trong tháng
  int _getDaysInMonth(int month, int year) {
    switch (month) {
      case 1: case 3: case 5: case 7: case 8: case 10: case 12:
        return 31;
      case 4: case 6: case 9: case 11:
        return 30;
      case 2:
        return _isLeapYear(year) ? 29 : 28;
      default:
        return 31;
    }
  }
  
  // Validation ngày sinh với thông báo lỗi chi tiết
  String? _validateBirthDate(String displayDate) {
    if (displayDate.isEmpty) {
      return 'Vui lòng nhập ngày sinh';
    }
    
    try {
      final parts = displayDate.split('/');
      if (parts.length != 3) {
        return 'DD/MM/YYYY';
      }
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      
      // Xử lý năm 2 chữ số
      if (year < 100) {
        year = 2000 + year;
      }
      
      // Kiểm tra tháng hợp lệ
      if (month < 1 || month > 12) {
        return 'Invalid month. Month must be from 1 to 12';
      }
      
      // Kiểm tra ngày hợp lệ trong tháng
      final maxDaysInMonth = _getDaysInMonth(month, year);
      if (day < 1 || day > maxDaysInMonth) {
        if (month == 2 && day == 29 && !_isLeapYear(year)) {
          return 'Year $year is not a leap year, February only has 28 days';
        }
        return 'Invalid date. Month $month only has maximum $maxDaysInMonth days';
      }
      
      // Kiểm tra tuổi hợp lý (từ 18 đến 100 tuổi)
      // LUÔN lấy thời gian hiện tại động, không bao giờ cache
      final currentDate = DateTime.now();
      final birthDate = DateTime(year, month, day);
      
      // Tính tuổi chính xác dựa trên ngày hiện tại
      final age = currentDate.difference(birthDate).inDays / 365.25;
      
      if (age < 18) {
        return 'Age must be 18 or older';
      }
      
      if (age > 100) {
        return 'Age cannot exceed 100 years';
      }
      
      // Kiểm tra ngày sinh không được trong tương lai (so với thời gian hiện tại)
      if (birthDate.isAfter(currentDate)) {
        return 'Birth date cannot be in the future (today: ${currentDate.day}/${currentDate.month}/${currentDate.year})';
      }
      
      return null; // Không có lỗi
    } catch (e) {
      return 'Please enter in DD/MM/YYYY format';
    }
  }

  // Chuyển đổi từ định dạng DD/MM/YYYY sang YYYY-MM-DD để gửi lên server
  String _convertToAPIDateFormat(String displayDate) {
    try {
      final parts = displayDate.split('/');
      if (parts.length == 3) {
        // Đảm bảo năm có 4 chữ số
        int year = int.parse(parts[2]);
        if (year < 100) {
          year = 2000 + year;
        }
        
        // Lấy ngày và tháng
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        // Định dạng lại thành YYYY-MM-DD
        final formattedDate = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        print('🔄 EditProfileScreen: Date conversion for API');
        print('   Display date: $displayDate');
        print('   API format: $formattedDate');
        return formattedDate;
      }
      return displayDate;
    } catch (e) {
      print('⚠️ EditProfileScreen: Error converting date format: $e');
      return '2000-01-01'; // Ngày mặc định nếu có lỗi
    }
  }

  // Request permissions for camera and gallery access
  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'This feature requires permission to access your camera or gallery. '
              'Please enable it in app settings.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    
    return false;
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    // Request storage permission first
    final hasPermission = await _requestPermission(Permission.photos);
    if (!hasPermission) {
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce size
        maxWidth: 800,    // Limit image dimensions
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
        print('🖼️ EditProfileScreen: Image selected from gallery');
        print('   Path: ${image.path}');
      }
    } catch (e) {
      print('❌ EditProfileScreen: Error picking image from gallery: $e');
      _handleImagePickerError(e);
    }
  }
  
  // Capture new image from camera
  Future<void> _pickImageFromCamera() async {
    // Request camera permission first
    final hasPermission = await _requestPermission(Permission.camera);
    if (!hasPermission) {
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress image to reduce size
        maxWidth: 800,    // Limit image dimensions
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
        print('📸 EditProfileScreen: Image captured from camera');
        print('   Path: ${image.path}');
      }
    } catch (e) {
      print('❌ EditProfileScreen: Error capturing image from camera: $e');
      _handleImagePickerError(e);
    }
  }
  
  // Handle errors from image picker
  void _handleImagePickerError(dynamic error) {
    String errorMessage = 'Unable to select image';
    
    // Analyze error type to display appropriate message
    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
          errorMessage = 'Camera access denied. Please grant permission in settings.';
          break;
        case 'photo_access_denied':
          errorMessage = 'Gallery access denied. Please grant permission in settings.';
          break;
        case 'invalid_image':
          errorMessage = 'Invalid or corrupted image.';
          break;
        default:
          errorMessage = 'Error: ${error.message}';
      }
    }
    
    // Display error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
  
  // Show bottom sheet to select image source
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              if (_selectedAvatar != null || (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty))
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Remove Profile Picture'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedAvatar = null;
                      // Mark as wanting to delete current image
                      // However, API may not support image deletion
                      // so we only delete on client side
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    print('🔄 EditProfileScreen: _saveProfile() called');
    print('   Name: ${_nameController.text}');
    print('   Email: ${_emailController.text}');
    print('   Phone: ${_phoneController.text}');
    print('   Birthday: ${_dateOfBirthController.text}');
    print('   Gender: $_selectedGender');
    print('   Avatar selected: ${_selectedAvatar != null}');
    
    // Validate ngày sinh trước khi lưu
    final dateError = _validateBirthDate(_dateOfBirthController.text.trim());
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate tên không được rỗng
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ tên'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (_emailController.text.trim().isNotEmpty && !emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Định dạng email không đúng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      print('📋 EditProfileScreen: ProfileService obtained');
      print('   ProfileService isLoading: ${profileService.isLoading}');
      print('   ProfileService error: ${profileService.error}');
      
      // Split name into firstName and lastName
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      // Convert from DD/MM/YYYY to YYYY-MM-DD format
      final apiDateFormat = _convertToAPIDateFormat(_dateOfBirthController.text.trim());
      
      // Call the updateProfile method with correct field names
      print('📞 EditProfileScreen: Calling profileService.updateProfile()');
      print('   firstName: $firstName');
      print('   lastName: $lastName');
      print('   email: ${_emailController.text.trim()}');
      print('   birthday: $apiDateFormat (original: ${_dateOfBirthController.text.trim()})');
      print('   gender: $_selectedGender');
      print('   avatar: ${_selectedAvatar?.path ?? 'No new avatar'}');
      
      final updatedProfile = await profileService.updateProfile(
        email: _emailController.text.trim(),
        firstName: firstName,
        lastName: lastName,
        birthday: apiDateFormat,
        gender: _selectedGender,
        avatarFile: _selectedAvatar,
      );
      
      print('📋 EditProfileScreen: updateProfile() completed');
      print('   Result: ${updatedProfile != null ? 'Success' : 'Failed'}');
      print('   ProfileService error: ${profileService.error}');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (updatedProfile != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      } else {
        // Show error message
        final errorMessage = profileService.error ?? 'Failed to update profile. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar with selection option
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedAvatar != null 
                        ? FileImage(_selectedAvatar!) 
                        : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                            ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                            : null),
                    child: _selectedAvatar == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Hint text for avatar
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Text(
                'Tap to change profile picture',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Form fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              enabled: false, // Phone number cannot be edited
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // Date of Birth with auto-formatting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _dateError != null ? Colors.red : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _dateError != null ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _dateError != null ? Colors.red : AppColors.primary,
                      ),
                    ),
                    hintText: 'DD/MM/YYYY',
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: _dateError != null ? Colors.red : null,
                    ),
                    suffixIcon: _showDatePickerIcon 
                      ? IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: () => _selectDate(context),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _dateOfBirthController.clear();
                            });
                          },
                        ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    DateInputFormatter(),
                  ],
                  onTap: () {
                    // Nếu trường rỗng, hiển thị date picker
                    if (_dateOfBirthController.text.isEmpty) {
                      _selectDate(context);
                    }
                  },
                ),
                // Hiển thị lỗi validation nếu có
                if (_dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      _dateError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Gender selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text('Gender'),
                  const Spacer(),
                  Row(
                    children: [
                      Radio(
                        value: 'MALE',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value.toString();
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text('Male'),
                      const SizedBox(width: 16),
                      Radio(
                        value: 'FEMALE',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value.toString();
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text('Female'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Save button
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Information',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}