import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/main.dart'; // Import main to access global nostr
import 'package:nostrmo/theme/app_colors.dart';
import '../models/listing_model.dart';
import '../providers/listing_provider.dart';

class CreateEditListingScreen extends ConsumerStatefulWidget {
  final ListingModel? listing; // If provided, we're editing an existing listing
  final String? groupId; // If provided, this listing will be scoped to a group
  final ListingType? type; // If provided, initializes the type (ask/offer)

  const CreateEditListingScreen({
    this.listing,
    this.groupId,
    this.type,
    super.key,
  });

  @override
  ConsumerState<CreateEditListingScreen> createState() => _CreateEditListingScreenState();
}

class _CreateEditListingScreenState extends ConsumerState<CreateEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late ListingType _type;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _paymentInfoController;
  DateTime? _expiresAt;
  List<String> _imageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if editing
    // Use provided type if available, otherwise use listing type or default to Ask
    _type = widget.type ?? widget.listing?.type ?? ListingType.ask;
    _titleController = TextEditingController(text: widget.listing?.title ?? '');
    _contentController = TextEditingController(text: widget.listing?.content ?? '');
    _locationController = TextEditingController(text: widget.listing?.location ?? '');
    _priceController = TextEditingController(text: widget.listing?.price ?? '');
    _paymentInfoController = TextEditingController(text: widget.listing?.paymentInfo ?? '');
    _expiresAt = widget.listing?.expiresAt;
    _imageUrls = widget.listing?.imageUrls ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _paymentInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.listing == null) {
        // Create new listing
        // Get pubkey from global nostr instance
        final pubkey = nostr?.publicKey;
        if (pubkey == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not logged in')),
          );
          setState(() => _isLoading = false);
          return;
        }

        await ref.read(listingProvider.notifier).createListing(
          // pubkey: 'TODO: Get current user pubkey', // Removed placeholder
          type: _type,
          title: _titleController.text,
          content: _contentController.text,
          groupId: widget.groupId,
          expiresAt: _expiresAt,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          price: _priceController.text.isNotEmpty ? _priceController.text : null,
          imageUrls: _imageUrls,
          paymentInfo: _paymentInfoController.text.isNotEmpty ? _paymentInfoController.text : null,
        );
      } else {
        // Update existing listing
        await ref.read(listingProvider.notifier).updateListing(
          widget.listing!.copyWith(
            type: _type,
            title: _titleController.text,
            content: _contentController.text,
            groupId: widget.groupId,
            expiresAt: _expiresAt,
            location: _locationController.text.isNotEmpty ? _locationController.text : null,
            price: _priceController.text.isNotEmpty ? _priceController.text : null,
            imageUrls: _imageUrls,
            paymentInfo: _paymentInfoController.text.isNotEmpty ? _paymentInfoController.text : null,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _addImage() async {
    // TODO: Implement image upload
    // For now, just add a placeholder URL
    setState(() {
      _imageUrls.add('https://placeholder.com/150x150');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    // Create text style for form inputs with high contrast
    final inputStyle = TextStyle(
      color: context.colors.primaryText,
      fontSize: 16,
    );
    
    // Create form decoration for consistent styling
    InputDecoration getInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: context.colors.secondaryText,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: context.colors.divider,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: themeData.primaryColor,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red.shade500,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: context.colors.feedBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 16,
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listing == null ? 'Create Listing' : 'Edit Listing',
          style: TextStyle(color: context.colors.primaryText),
        ),
        iconTheme: IconThemeData(color: context.colors.primaryText),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type selector with better colors
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colors.divider, 
                          width: 1.5,
                        ),
                      ),
                      child: SegmentedButton<ListingType>(
                        segments: [
                          ButtonSegment(
                            value: ListingType.ask,
                            label: Text(
                              'ASK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _type == ListingType.ask 
                                  ? Colors.white 
                                  : Colors.blue,
                              ),
                            ),
                            icon: Icon(
                              Icons.help_outline,
                              color: _type == ListingType.ask 
                                ? Colors.white 
                                : Colors.blue,
                            ),
                          ),
                          ButtonSegment(
                            value: ListingType.offer,
                            label: Text(
                              'OFFER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _type == ListingType.offer 
                                  ? Colors.white 
                                  : Colors.green,
                              ),
                            ),
                            icon: Icon(
                              Icons.local_offer_outlined,
                              color: _type == ListingType.offer 
                                ? Colors.white 
                                : Colors.green,
                            ),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (Set<ListingType> newSelection) {
                          setState(() => _type = newSelection.first);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) {
                              if (states.contains(MaterialState.selected)) {
                                return _type == ListingType.ask ? Colors.blue : Colors.green;
                              }
                              return customColors.feedBgColor;
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _titleController,
                      style: inputStyle,
                      decoration: getInputDecoration('Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _contentController,
                      style: inputStyle,
                      decoration: getInputDecoration('Description'),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Expansion tile with improved styling
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Additional Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: customColors.primaryForegroundColor,
                          ),
                        ),
                        iconColor: themeData.primaryColor,
                        collapsedIconColor: customColors.secondaryForegroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: customColors.separatorColor,
                            width: 1.5,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _locationController,
                                  style: inputStyle,
                                  decoration: getInputDecoration('Location'),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                TextFormField(
                                  controller: _priceController,
                                  style: inputStyle,
                                  decoration: getInputDecoration('Price'),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                TextFormField(
                                  controller: _paymentInfoController,
                                  style: inputStyle,
                                  decoration: getInputDecoration('Payment Information'),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                Card(
                                  elevation: 0,
                                  color: customColors.feedBgColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: customColors.separatorColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      'Expiration Date',
                                      style: TextStyle(
                                        color: customColors.primaryForegroundColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _expiresAt != null
                                        ? '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}'
                                        : 'No expiration date set',
                                      style: TextStyle(
                                        color: customColors.secondaryForegroundColor,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.calendar_today,
                                        color: themeData.primaryColor,
                                      ),
                                      onPressed: _selectExpirationDate,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                if (_imageUrls.isNotEmpty) ...[
                                  Text(
                                    'Images',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: customColors.primaryForegroundColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: customColors.feedBgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: customColors.separatorColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.all(10),
                                      itemCount: _imageUrls.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(right: 12.0),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: customColors.separatorColor,
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _imageUrls[index],
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  iconSize: 18,
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _imageUrls.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Add image button with improved styling
                                ElevatedButton.icon(
                                  onPressed: _addImage,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('Add Image'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: themeData.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button with improved styling and dark mode support
                    ElevatedButton(
                      onPressed: _saveListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == ListingType.ask 
                          ? (isDarkMode ? Colors.blue.shade700 : Colors.blue)
                          : (isDarkMode ? Colors.green.shade700 : Colors.green),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: isDarkMode ? 3 : 2,
                      ),
                      child: Text(
                        widget.listing == null ? 'Create Listing' : 'Update Listing',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 