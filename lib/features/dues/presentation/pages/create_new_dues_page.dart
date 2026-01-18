import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/dues/data/models/due_creation_data.dart';

class CreateNewDuesPage extends StatefulWidget {
  const CreateNewDuesPage({super.key});

  @override
  State<CreateNewDuesPage> createState() => _CreateNewDuesPageState();
}

class _CreateNewDuesPageState extends State<CreateNewDuesPage> {
  final TextEditingController _dueNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isFormValid = false;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _dueNameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _dueNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _dueNameController.text.trim().isNotEmpty;
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement image picking from gallery
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement image capture from camera
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 20),
                    Text(
                      'Create new',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 134,
                    decoration: BoxDecoration(
                      color: Color(0xFFD1FAFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: _isUploadingImage
                        ? CircularProgressIndicator()
                        : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _imageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/svgs/dues/Frame 2609295.svg'),
                  ),
                ),
                const SizedBox(height: 50),
                _buildTextField(
                  hintText: 'e.g Monthly dues',
                  labelText: 'Name your Due',
                  controller: _dueNameController,
                ),
                const SizedBox(height: 25),
                _buildTextField(
                  hintText: 'Explain what these dues cover',
                  labelText: 'Description(Optional)',
                  maxLines: 3,
                  controller: _descriptionController,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: DefaultButton(
          isButtonEnabled: _isFormValid,
          onPressed: _isFormValid
              ? () {
                  // Create due data with current form data
                  final dueData = DueCreationData(
                    title: _dueNameController.text.trim(),
                    description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                    imageUrl: _imageUrl,
                  );

                  // Pass data to next screen via extra
                  context.push(AppRoutes.configureDues, extra: dueData);
                }
              : null,
          title: 'Next',
          height: 54,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          buttonColor: Color(0xFF21A8FB),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required String labelText,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
