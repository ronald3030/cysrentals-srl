import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/equipment.dart';
import '../../providers/equipment_provider.dart';
import '../../services/storage_service.dart';

class EquipmentFormScreen extends StatefulWidget {
  final Equipment? equipment; // null para crear, con datos para editar
  final bool reduceMotion;

  const EquipmentFormScreen({
    super.key,
    this.equipment,
    required this.reduceMotion,
  });

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedCategory = 'Construcción';
  EquipmentStatus _selectedStatus = EquipmentStatus.available;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  final List<String> _categories = [
    'Construcción',
    'Jardinería',
    'Herramientas Eléctricas',
    'Maquinaria Pesada',
    'Equipo de Seguridad',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      // Modo edición
      _nameController.text = widget.equipment!.name;
      _descriptionController.text = widget.equipment!.description;
      _dailyRateController.text = widget.equipment!.dailyRate?.toString() ?? '';
      _locationController.text = widget.equipment!.location ?? '';
      _selectedCategory = widget.equipment!.category;
      _selectedStatus = widget.equipment!.status;
      _existingImageUrl = widget.equipment!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dailyRateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryRed),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryRed),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<EquipmentProvider>();
      String? imageUrl = _existingImageUrl;

      // Subir imagen si hay una nueva seleccionada
      if (_selectedImage != null) {
        // Si hay imagen anterior y estamos en modo edición, eliminarla
        if (_existingImageUrl != null && widget.equipment != null) {
          await StorageService.deleteEquipmentImage(_existingImageUrl!);
        }

        // Generar ID temporal para nuevos equipos
        final equipmentId = widget.equipment?.id ?? 
            'E${DateTime.now().millisecondsSinceEpoch}';
        
        imageUrl = await StorageService.uploadEquipmentImage(
          _selectedImage!,
          equipmentId,
        );
      }

      final equipment = Equipment(
        id: widget.equipment?.id ?? 'E${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        status: _selectedStatus,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        dailyRate: double.tryParse(_dailyRateController.text),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        customer: widget.equipment?.customer,
        rentalStartDate: widget.equipment?.rentalStartDate,
        rentalEndDate: widget.equipment?.rentalEndDate,
        maintenanceHistory: widget.equipment?.maintenanceHistory ?? [],
      );

      if (widget.equipment == null) {
        // Crear nuevo
        await provider.addEquipment(equipment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipo agregado exitosamente'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } else {
        // Actualizar existente
        await provider.updateEquipment(equipment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipo actualizado exitosamente'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment == null ? 'Agregar Equipo' : 'Editar Equipo'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: AppTheme.primaryWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen
                    _buildImageSection(),
                    const SizedBox(height: 24),

                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Equipo *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el nombre del equipo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Estado
                    DropdownButtonFormField<EquipmentStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: EquipmentStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor describe el equipo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tarifa diaria
                    TextFormField(
                      controller: _dailyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Tarifa Diaria (RD\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final rate = double.tryParse(value);
                          if (rate == null || rate <= 0) {
                            return 'Por favor ingresa un monto válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ubicación
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _saveEquipment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              foregroundColor: AppTheme.primaryWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(widget.equipment == null 
                                ? 'Agregar Equipo' 
                                : 'Guardar Cambios'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del Equipo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : _existingImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null || _existingImageUrl != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _existingImageUrl = null;
              });
            },
            icon: const Icon(Icons.delete, color: AppTheme.errorRed),
            label: const Text('Eliminar imagen', style: TextStyle(color: AppTheme.errorRed)),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: AppTheme.mediumGray,
        ),
        SizedBox(height: 8),
        Text(
          'Toca para seleccionar foto',
          style: TextStyle(color: AppTheme.mediumGray),
        ),
        SizedBox(height: 4),
        Text(
          'Desde galería o cámara',
          style: TextStyle(
            color: AppTheme.mediumGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
