import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';

class ExpirationNotificationCard extends StatelessWidget {
  final String title;
  final List<MedicationFirebase> medications;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  const ExpirationNotificationCard({
    Key? key,
    required this.title,
    required this.medications,
    required this.color,
    required this.iconColor,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${medications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (int i = 0; i < medications.length && i < 3; i++)
                    _buildMedicationItem(medications[i]),
                  if (medications.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Y ${medications.length - 3} más...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(MedicationFirebase medication) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            color: Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              medication.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (medication.expirationDate != null)
            Text(
              DateFormat('dd/MM/yyyy').format(medication.expirationDate!),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
