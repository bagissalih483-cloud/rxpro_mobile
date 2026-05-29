import 'package:flutter/material.dart';

import 'staff_tasks_entry_page.dart';

class BusinessLiveFlowPage extends StatelessWidget {
  const BusinessLiveFlowPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return StaffTasksEntryPage(
      businessId: businessId,
      title: 'Canlı Akış',
      workspaceTitle: 'Canlı Akış',
      tasksOnlyWorkspace: true,
    );
  }
}
