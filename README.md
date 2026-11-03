# NET4207 Stock Inventory Manager

## Project Overview
Stock Inventory Manager is a Flutter application developed for the NET4207 Cross Platform Mobile App Development lab test. It allows a retailer to add, store, retrieve, search and filter stock inventory using Firebase Cloud Firestore.

## Technologies
- Flutter 3.47.4
- Dart
- Firebase Cloud Firestore
- firebase_core
- cloud_firestore

## Firebase Configuration
Firebase Project ID: `stock-inventory-manager-f3b60`

The application uses FlutterFire configuration through `lib/firebase_options.dart`.

## Setup and Run
1. Install Flutter and configure the development environment.
2. Clone this repository.
3. Open the project directory.
4. Install dependencies:

   `flutter pub get`

5. Configure Firebase if using a different environment.
6. Run the application:

   `flutter run -d chrome`

For Android, use:

   `flutter run`

## Firestore Data Model
Collection: `stockItems`

| Field | Type | Requirement |
|---|---|---|
| sku | String | STK- followed by three digits |
| itemName | String | Trimmed, minimum 3 characters |
| category | String | Electronics, Stationery, Hardware or Grocery |
| quantity | Integer | 0 or above |
| unitPrice | Number | Greater than 0, in RM |
| reorderLevel | Integer | 0 or above |
| createdAt | Timestamp | Server timestamp |

Firestore generates document IDs automatically.

## Form Validation
The form validates all six required inputs before saving. Invalid data must not be written to Firestore. The application provides field-level validation messages and save feedback.

## Search and Filtering
The inventory supports partial, case-insensitive keyword matching against item name or SKU. Users can filter by category, display low-stock items where quantity is less than or equal to reorder level, combine active filters, sort by quantity in ascending or descending order, and clear filters.

## Test Log

| Test | Expected result | Actual result |
|---|---|---|
| Invalid form submission | Inline errors; no Firestore write | To be completed |
| Valid save and retrieval | Record saved and displayed after reload | Firestore save previously observed; reload verification pending |
| Combined search | Search mouse + Electronics + Low Stock returns STK-103 only | To be completed |

## Evidence
Add screenshots of:
- Invalid form validation
- Successful Firestore save and inventory list
- Firestore collection and documents
- Combined search and low-stock filtering
- Quantity sorting

## Code Quality
Run `flutter analyze` to check the Dart source code.
