import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../models/listing_model.dart';
import '../models/response_model.dart';
import '../providers/response_provider.dart';

class ResponseDialog extends ConsumerStatefulWidget {
  final ListingModel listing;
  final ResponseType initialResponseType;

  const ResponseDialog({
    required this.listing,
    required this.initialResponseType,
    super.key,
  });

  @override
  ConsumerState<ResponseDialog> createState() => _ResponseDialogState();
}

class _ResponseDialogState extends ConsumerState<ResponseDialog> {
  late ResponseType _responseType;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _responseType = widget.initialResponseType;
    
    // Pre-fill location if listing has a location
    if (widget.listing.location != null) {
      _locationController.text = widget.listing.location!;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    if (_contentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a message';
        _isSubmitting = false;
      });
      return;
    }

    try {
      await ref.read(responseProvider.notifier).createResponse(
        listingEventId: widget.listing.id,
        listingPubkey: widget.listing.pubkey,
        listingD: widget.listing.d,
        responseType: _responseType,
        content: _contentController.text.trim(),
        price: _priceController.text.isNotEmpty ? _priceController.text.trim() : null,
        location: _locationController.text.isNotEmpty ? _locationController.text.trim() : null,
        availability: _availabilityController.text.isNotEmpty ? _availabilityController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send response: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog title
            Text(
              widget.listing.type == ListingType.ask 
                ? 'Respond to Ask' 
                : 'Respond to Offer',
              style: themeData.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Listing title
            Text(
              widget.listing.title,
              style: themeData.textTheme.titleMedium,
            ),
            
            const SizedBox(height: 24),
            
            // Response type selector
            Text(
              'How would you like to respond?',
              style: themeData.textTheme.titleSmall,
            ),
            
            const SizedBox(height: 8),
            
            // Radio buttons for response type
            _buildResponseTypeSelector(),
            
            const SizedBox(height: 16),
            
            // Message field
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Your message',
                hintText: _getMessageHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: customColors.feedBgColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Optional fields section
            ExpansionTile(
              title: const Text('Additional Details (Optional)'),
              childrenPadding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (_responseType == ResponseType.help || _responseType == ResponseType.offer)
                  TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (if applicable)',
                      hintText: 'e.g., 50 sats, Free, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: customColors.feedBgColor,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                TextField(
                  controller: _availabilityController,
                  decoration: InputDecoration(
                    labelText: 'When are you available?',
                    hintText: 'e.g., Weekday evenings, This Saturday, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: customColors.feedBgColor,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location (if applicable)',
                    hintText: 'e.g., Downtown, Can deliver, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: customColors.feedBgColor,
                  ),
                ),
              ],
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_getButtonText()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTypeSelector() {
    return Column(
      children: [
        if (widget.listing.type == ListingType.ask) ...[
          // Options for Ask
          _buildResponseTypeRadio(
            ResponseType.help,
            'I can help',
            'Offer your assistance for this request',
            Colors.blue,
          ),
          _buildResponseTypeRadio(
            ResponseType.question,
            'Ask a question',
            'Get more information before committing',
            Colors.orange,
          ),
        ] else ...[
          // Options for Offer
          _buildResponseTypeRadio(
            ResponseType.interest,
            'I\'m interested',
            'Express interest in this offer',
            Colors.green,
          ),
          _buildResponseTypeRadio(
            ResponseType.question,
            'Ask a question',
            'Get more information before committing',
            Colors.orange,
          ),
          _buildResponseTypeRadio(
            ResponseType.offer,
            'Make a counter-offer',
            'Suggest different terms',
            Colors.purple,
          ),
        ],
      ],
    );
  }

  Widget _buildResponseTypeRadio(
    ResponseType type,
    String title,
    String subtitle,
    Color color,
  ) {
    return RadioListTile<ResponseType>(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      value: type,
      groupValue: _responseType,
      activeColor: color,
      onChanged: (ResponseType? value) {
        if (value != null) {
          setState(() {
            _responseType = value;
          });
        }
      },
    );
  }

  String _getMessageHint() {
    switch (_responseType) {
      case ResponseType.help:
        return 'Describe how you can help with this request...';
      case ResponseType.interest:
        return 'Let them know why you\'re interested...';
      case ResponseType.question:
        return 'What would you like to know?';
      case ResponseType.offer:
        return 'Describe your counter-offer...';
    }
  }

  String _getButtonText() {
    switch (_responseType) {
      case ResponseType.help:
        return 'Send Help Offer';
      case ResponseType.interest:
        return 'Express Interest';
      case ResponseType.question:
        return 'Ask Question';
      case ResponseType.offer:
        return 'Send Counter-Offer';
    }
  }

  Color _getButtonColor() {
    switch (_responseType) {
      case ResponseType.help:
        return Colors.blue;
      case ResponseType.interest:
        return Colors.green;
      case ResponseType.question:
        return Colors.orange;
      case ResponseType.offer:
        return Colors.purple;
    }
  }
}