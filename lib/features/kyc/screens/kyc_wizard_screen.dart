import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/document_upload_tile.dart';
import '../../../core/services/auth_service.dart';

class KycWizardScreen extends ConsumerStatefulWidget {
  const KycWizardScreen({super.key});

  @override
  ConsumerState<KycWizardScreen> createState() => _KycWizardScreenState();
}

class _KycWizardScreenState extends ConsumerState<KycWizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isPickingImage = false; // Guard against double-tap / already_active error

  // Controllers Step 2
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _rccmController = TextEditingController();
  final _cniManagerController = TextEditingController();

  // Files Step 3
  File? _cniRecto;
  File? _cniVerso;
  File? _rccmDoc;
  File? _proofOfAddress;

  Future<void> _pickImage(void Function(File) onPicked) async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      // Show a bottom sheet to choose source (needed on emulator which has empty gallery)
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Choisir une source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF1B4332)),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1B4332)),
                title: const Text('Galerie photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile != null) {
        setState(() {
          onPicked(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'accéder à la source: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _submitKyc() async {
    // Validate Step 3
    if (_cniRecto == null || _cniVerso == null || _proofOfAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez fournir tous les documents requis.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = ref.read(authServiceProvider);
      
      // Build documents list & types — backend expects arrays
      final List<File> docFiles = [_cniRecto!, _cniVerso!, _proofOfAddress!];
      final List<String> docTypes = ['cni', 'cni', 'other'];

      if (_rccmDoc != null) {
        docFiles.add(_rccmDoc!);
        docTypes.add('rccm');
      }

      // Field names map to backend validation: business_name, business_address, rccm_number, cni_number
      final data = {
        'business_name':    _companyNameController.text,
        'business_address': _companyAddressController.text,
        'rccm_number':      _rccmController.text,
        'cni_number':       _cniManagerController.text,
      };

      final response = await authService.submitKyc(data, docFiles, docTypes);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) context.go('/kyc-pending');
      } else {
        throw Exception('Erreur lors de la soumission de la demande.');
      }
    } catch (e) {
      if (mounted) {
        // Show the actual error message from the backend
        String msg = e.toString();
        if (e is Exception) msg = msg.replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final phone = ref.watch(authProvider).phoneNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification KYC'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            setState(() => _currentStep += 1);
          } else if (_currentStep == 1) {
            if (_companyNameController.text.isEmpty ||
                _companyAddressController.text.isEmpty ||
                _cniManagerController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez remplir les champs obligatoires.')),
              );
              return;
            }
            setState(() => _currentStep += 1);
          } else if (_currentStep == 2) {
            _submitKyc();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : details.onStepContinue,
                    child: _isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Soumettre ma demande' : 'Continuer'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : details.onStepCancel,
                      child: const Text('Retour'),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Identité'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                TextField(
                  controller: TextEditingController(text: user?.name ?? ''),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: user?.phone ?? phone ?? ''),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Entreprise'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                TextField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'entreprise *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyAddressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse de l\'entreprise *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rccmController,
                  decoration: InputDecoration(
                    labelText: 'Numéro RCCM (si applicable)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cniManagerController,
                  decoration: InputDecoration(
                    labelText: 'Numéro CNI du gérant *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Documents'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                DocumentUploadTile(
                  title: 'Carte Nationale d\'Identité (Recto)',
                  isRequired: true,
                  uploadedFile: _cniRecto,
                  onUpload: () => _pickImage((f) => _cniRecto = f),
                ),
                DocumentUploadTile(
                  title: 'Carte Nationale d\'Identité (Verso)',
                  isRequired: true,
                  uploadedFile: _cniVerso,
                  onUpload: () => _pickImage((f) => _cniVerso = f),
                ),
                DocumentUploadTile(
                  title: 'Justificatif de domicile',
                  isRequired: true,
                  uploadedFile: _proofOfAddress,
                  onUpload: () => _pickImage((f) => _proofOfAddress = f),
                ),
                DocumentUploadTile(
                  title: 'RCCM',
                  isRequired: false,
                  uploadedFile: _rccmDoc,
                  onUpload: () => _pickImage((f) => _rccmDoc = f),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
