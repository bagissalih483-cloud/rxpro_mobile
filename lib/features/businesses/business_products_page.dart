import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import '../../core/firestore/firestore_fields.dart';
import '../../core/responsive/rx_keyboard_shortcuts.dart';
import '../../core/responsive/rx_responsive_grid.dart';
import 'package:flutter/material.dart';

import 'data/business_products_repository.dart';
import 'domain/business_product_policy.dart';
import 'presentation/business_products_controller.dart';
import 'presentation/widgets/business_stock_ledger_list.dart';
import 'services/business_products_service.dart';

part 'business_products_shell_part.dart';
part 'business_product_form_part.dart';
part 'business_products_list_part.dart';
part 'business_products_stock_part.dart';
part 'business_products_info_part.dart';
