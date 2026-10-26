import 'package:flutter/foundation.dart';

/// Supported Languages: Hinglish, हिंदी (Hindi), English
enum AppLang { hinglish, hindi, english }

AppLang currentAppLang(String langName) {
  final l = langName.trim().toLowerCase();
  if (l == 'hindi' || l == 'हिंदी' || l.contains('हिन्द') || l.contains('हिंदी')) {
    return AppLang.hindi;
  } else if (l == 'english' || l == 'en') {
    return AppLang.english;
  }
  return AppLang.hinglish;
}

class LocalizationService {
  LocalizationService._();

  static final Map<String, Map<AppLang, String>> _dict = {
    // Navigation
    'nav_home': {
      AppLang.hinglish: 'Home',
      AppLang.hindi: 'होम',
      AppLang.english: 'Home',
    },
    'nav_khata': {
      AppLang.hinglish: 'Khata',
      AppLang.hindi: 'खाता',
      AppLang.english: 'Ledger',
    },
    'nav_scan': {
      AppLang.hinglish: 'Scan',
      AppLang.hindi: 'स्कैन',
      AppLang.english: 'Scan',
    },
    'nav_reports': {
      AppLang.hinglish: 'Reports',
      AppLang.hindi: 'रिपोर्ट',
      AppLang.english: 'Reports',
    },

    // Header & Shop
    'set_shop_name': {
      AppLang.hinglish: 'Dukan Ka Naam Set Karein',
      AppLang.hindi: 'दुकान का नाम सेट करें',
      AppLang.english: 'Set Shop Name',
    },
    'welcome_merchant': {
      AppLang.hinglish: 'Namaste Vyapari Ji 🙏',
      AppLang.hindi: 'नमस्ते व्यापारी जी 🙏',
      AppLang.english: 'Welcome Merchant 🙏',
    },
    'sync': {
      AppLang.hinglish: 'Sync',
      AppLang.hindi: 'सिंक',
      AppLang.english: 'Sync',
    },
    'edit_shop_title': {
      AppLang.hinglish: 'Dukan Ka Naam Badlein',
      AppLang.hindi: 'दुकान का नाम बदलें',
      AppLang.english: 'Edit Shop Name',
    },
    'shop_name_hint': {
      AppLang.hinglish: 'Jaise: Gupta General Store',
      AppLang.hindi: 'जैसे: गुप्ता जनरल स्टोर',
      AppLang.english: 'e.g. Gupta General Store',
    },
    'save': {
      AppLang.hinglish: 'Save Karein',
      AppLang.hindi: 'सुरक्षित करें',
      AppLang.english: 'Save',
    },
    'cancel': {
      AppLang.hinglish: 'Radd Karein',
      AppLang.hindi: 'रद्द करें',
      AppLang.english: 'Cancel',
    },

    // Period Selectors
    'period_today': {
      AppLang.hinglish: 'Today',
      AppLang.hindi: 'आज',
      AppLang.english: 'Today',
    },
    'period_yesterday': {
      AppLang.hinglish: 'Yesterday',
      AppLang.hindi: 'कल',
      AppLang.english: 'Yesterday',
    },
    'period_week': {
      AppLang.hinglish: 'This Week',
      AppLang.hindi: 'इस हफ्ते',
      AppLang.english: 'This Week',
    },
    'period_month': {
      AppLang.hinglish: 'This Month',
      AppLang.hindi: 'इस महीने',
      AppLang.english: 'This Month',
    },

    // Dues Summary Card
    'total_udhaar_receive': {
      AppLang.hinglish: 'KUL UDHAAR (LENE HAIN)',
      AppLang.hindi: 'कुल उधार (लेने हैं)',
      AppLang.english: 'TOTAL DUES (TO RECEIVE)',
    },
    'total_advance_give': {
      AppLang.hinglish: 'ADVANCE (DENE HAIN)',
      AppLang.hindi: 'एडवांस (देने हैं)',
      AppLang.english: 'ADVANCE (TO GIVE)',
    },
    'vasooli_target': {
      AppLang.hinglish: 'Vasooli Target',
      AppLang.hindi: 'वसूली लक्ष्य',
      AppLang.english: 'Recovery Target',
    },

    // Metrics
    'today_bikri': {
      AppLang.hinglish: 'Bikri',
      AppLang.hindi: 'बिक्री',
      AppLang.english: 'Sales',
    },
    'today_jama': {
      AppLang.hinglish: 'Jama',
      AppLang.hindi: 'जमा',
      AppLang.english: 'Received',
    },
    'today_udhaar': {
      AppLang.hinglish: 'Naya Udhaar',
      AppLang.hindi: 'नया उधार',
      AppLang.english: 'Credit Given',
    },

    // Quick Actions
    'action_add_customer': {
      AppLang.hinglish: '+ Grahak',
      AppLang.hindi: '+ नया ग्राहक',
      AppLang.english: '+ Customer',
    },
    'action_voice_entry': {
      AppLang.hinglish: 'Voice Entry',
      AppLang.hindi: 'बोलकर एंट्री',
      AppLang.english: 'Voice Entry',
    },
    'action_bill_scan': {
      AppLang.hinglish: 'Bill Scan',
      AppLang.hindi: 'बिल स्कैन',
      AppLang.english: 'Scan Bill',
    },
    'action_my_qr': {
      AppLang.hinglish: 'Mera QR',
      AppLang.hindi: 'मेरा QR',
      AppLang.english: 'My QR',
    },

    // AI Smart Alert
    'smart_alert_title': {
      AppLang.hinglish: 'Munim AI Smart Alert',
      AppLang.hindi: 'मुनीम AI स्मार्ट अलर्ट',
      AppLang.english: 'Munim AI Smart Alert',
    },
    'smart_alert_msg': {
      AppLang.hinglish: 'Aapka hisaab updated hai! Nayi entry voice se bolein.',
      AppLang.hindi: 'आपका हिसाब अपडेटेड है! नई एंट्री बोलकर दर्ज करें।',
      AppLang.english: 'Your accounts are updated! Tap mic for voice entry.',
    },
    'remind_btn': {
      AppLang.hinglish: 'Remind',
      AppLang.hindi: 'याद दिलाएं',
      AppLang.english: 'Remind',
    },

    // Top Dues Section
    'top_dues_title': {
      AppLang.hinglish: 'SABSE BADA UDHAAR (TOP DUES)',
      AppLang.hindi: 'सबसे बड़ा उधार (टॉप बकाया)',
      AppLang.english: 'TOP PENDING DUES',
    },
    'view_all': {
      AppLang.hinglish: 'Sabhi Dekhein',
      AppLang.hindi: 'सभी देखें',
      AppLang.english: 'View All',
    },
    'no_dues': {
      AppLang.hinglish: 'Koi baki udhaar nahi hai 🎉',
      AppLang.hindi: 'कोई बकाया उधार नहीं है 🎉',
      AppLang.english: 'No pending dues 🎉',
    },

    // Customer List
    'customer_khata_title': {
      AppLang.hinglish: 'KHAATA GRAHAK',
      AppLang.hindi: 'खाता ग्राहक',
      AppLang.english: 'CUSTOMERS',
    },
    'live_sync': {
      AppLang.hinglish: 'Live Sync',
      AppLang.hindi: 'लाइव सिंक',
      AppLang.english: 'Live Sync',
    },
    'no_customers_found': {
      AppLang.hinglish: 'Koi grahak ya entry nahi mili. Naya grahak jodein!',
      AppLang.hindi: 'कोई ग्राहक या एंट्री नहीं मिली। नया ग्राहक जोड़ें!',
      AppLang.english: 'No customers or entries found. Add a new customer!',
    },
    'add_customer': {
      AppLang.hinglish: 'Grahak Jodein',
      AppLang.hindi: 'ग्राहक जोड़ें',
      AppLang.english: 'Add Customer',
    },

    // Customer Row / Badges
    'settled': {
      AppLang.hinglish: 'Barabar',
      AppLang.hindi: 'बराबर',
      AppLang.english: 'Settled',
    },
    'to_receive': {
      AppLang.hinglish: 'Lena hai',
      AppLang.hindi: 'लेना है',
      AppLang.english: 'To receive',
    },
    'to_pay': {
      AppLang.hinglish: 'Dena hai',
      AppLang.hindi: 'देना है',
      AppLang.english: 'To pay',
    },
    'settled_tag': {
      AppLang.hinglish: 'Settled',
      AppLang.hindi: 'निपटारा',
      AppLang.english: 'Settled',
    },
    'advance_tag': {
      AppLang.hinglish: 'Advance',
      AppLang.hindi: 'एडवांस',
      AppLang.english: 'Advance',
    },
    'due_tag': {
      AppLang.hinglish: 'Due',
      AppLang.hindi: 'बकाया',
      AppLang.english: 'Due',
    },

    // Khata Directory Page
    'customer_directory': {
      AppLang.hinglish: 'Grahak Khata Directory',
      AppLang.hindi: 'ग्राहक खाता निर्देशिका',
      AppLang.english: 'Customer Ledger Directory',
    },
    'customers_connected': {
      AppLang.hinglish: 'Grahak judey hain',
      AppLang.hindi: 'ग्राहक जुड़े हैं',
      AppLang.english: 'Customers connected',
    },
    'new_customer': {
      AppLang.hinglish: 'Naya Grahak',
      AppLang.hindi: 'नया ग्राहक',
      AppLang.english: 'New Customer',
    },
    'search_placeholder': {
      AppLang.hinglish: 'Naam ya mobile number se khojein...',
      AppLang.hindi: 'नाम या मोबाइल नंबर से खोजें...',
      AppLang.english: 'Search by name or phone number...',
    },
    'filter_all': {
      AppLang.hinglish: 'Sabhi (All)',
      AppLang.hindi: 'सभी',
      AppLang.english: 'All',
    },
    'filter_due': {
      AppLang.hinglish: 'Baki Udhaar',
      AppLang.hindi: 'बकाया उधार',
      AppLang.english: 'Dues',
    },
    'filter_advance': {
      AppLang.hinglish: 'Advance / Jama',
      AppLang.hindi: 'एडवांस / जमा',
      AppLang.english: 'Advance / Paid',
    },
    'filter_settled': {
      AppLang.hinglish: 'Hisaab Barabar',
      AppLang.hindi: 'हिसाब बराबर',
      AppLang.english: 'Settled',
    },
    'no_customer_found': {
      AppLang.hinglish: 'Koi grahak nahi mila',
      AppLang.hindi: 'कोई ग्राहक नहीं मिला',
      AppLang.english: 'No customer found',
    },
    'add_customer_instruction': {
      AppLang.hinglish: 'Naya grahak jodne ke liye upar "+ Naya Grahak" par click karein.',
      AppLang.hindi: 'नया ग्राहक जोड़ने के लिए ऊपर "+ नया ग्राहक" पर क्लिक करें।',
      AppLang.english: 'Tap "+ New Customer" above to add a customer.',
    },

    // Ledger Page
    'no_transactions': {
      AppLang.hinglish: 'Koi transaction nahi mili',
      AppLang.hindi: 'कोई लेनदेन नहीं मिला',
      AppLang.english: 'No transactions yet',
    },
    'add_transaction_hint': {
      AppLang.hinglish: 'Niche diye gaye Udhaar ya Jama button se entry karein.',
      AppLang.hindi: 'नीचे दिए गए उधार या जमा बटन से एंट्री करें।',
      AppLang.english: 'Use the buttons below to record credit or payment.',
    },
    'gave_credit': {
      AppLang.hinglish: 'Udhaar Diya',
      AppLang.hindi: 'उधार दिया',
      AppLang.english: 'Gave Credit',
    },
    'got_payment': {
      AppLang.hinglish: 'Jama Mila',
      AppLang.hindi: 'जमा मिला',
      AppLang.english: 'Got Payment',
    },
    'whatsapp_reminder': {
      AppLang.hinglish: 'WhatsApp Taqaza / Reminder',
      AppLang.hindi: 'व्हाट्सएप तकाजा / रिमाइंडर',
      AppLang.english: 'WhatsApp Reminder',
    },
    'delete_entry_title': {
      AppLang.hinglish: 'Entry Delete Karein?',
      AppLang.hindi: 'एंट्री डिलीट करें?',
      AppLang.english: 'Delete Entry?',
    },
    'delete_entry_msg': {
      AppLang.hinglish: 'Yeh entry khate se hata di jayegi.',
      AppLang.hindi: 'यह एंट्री खाते से हटा दी जाएगी।',
      AppLang.english: 'This entry will be removed from the ledger.',
    },
    'yes_delete': {
      AppLang.hinglish: 'Haan, Delete Karein',
      AppLang.hindi: 'हाँ, हटाएं',
      AppLang.english: 'Yes, Delete',
    },

    // Chat / AI Page
    'chat_placeholder': {
      AppLang.hinglish: 'Bolein ya likhein jaise: Suresh 500...',
      AppLang.hindi: 'बोलें या लिखें जैसे: सुरेश 500...',
      AppLang.english: 'Speak or type e.g. Suresh 500...',
    },
    'chat_greeting': {
      AppLang.hinglish: 'Main aapka Munim Ji AI hoon. Koi bhi hisaab bolkar ya likhkar darj karein.',
      AppLang.hindi: 'मैं आपका मुनीम जी AI हूँ। कोई भी हिसाब बोलकर या लिखकर दर्ज करें।',
      AppLang.english: 'I am your Munim Ji AI assistant. Speak or type any transaction.',
    },
    'quick_p1': {
      AppLang.hinglish: 'Ramesh ko 500 ka udhaar likho',
      AppLang.hindi: 'रमेश को 500 का उधार लिखो',
      AppLang.english: 'Record 500 credit for Ramesh',
    },
    'quick_p2': {
      AppLang.hinglish: 'Suresh ne 1200 jama karwaye',
      AppLang.hindi: 'सुरेश ने 1200 जमा करवाए',
      AppLang.english: 'Suresh deposited 1200',
    },
    'quick_p3': {
      AppLang.hinglish: 'Aaj ki kul bikri kitni hui?',
      AppLang.hindi: 'आज की कुल बिक्री कितनी हुई?',
      AppLang.english: 'What were total sales today?',
    },
    'quick_p4': {
      AppLang.hinglish: 'Kiska kitna udhaar baki hai?',
      AppLang.hindi: 'किसका कितना उधार बाकी है?',
      AppLang.english: 'Who has pending dues?',
    },

    // Reports / Settings Page
    'download_reports': {
      AppLang.hinglish: 'REPORTS DOWNLOAD KAREIN',
      AppLang.hindi: 'रिपोर्ट डाउनलोड करें',
      AppLang.english: 'DOWNLOAD REPORTS',
    },
    'excel_export': {
      AppLang.hinglish: 'Excel Export',
      AppLang.hindi: 'एक्सेल एक्सपोर्ट',
      AppLang.english: 'Excel Export',
    },
    'pdf_summary': {
      AppLang.hinglish: 'PDF Summary',
      AppLang.hindi: 'पीडीएफ समरी',
      AppLang.english: 'PDF Summary',
    },
    'drive_backup': {
      AppLang.hinglish: 'Google Drive Backup',
      AppLang.hindi: 'गूगल ड्राइव बैकअप',
      AppLang.english: 'Google Drive Backup',
    },
    'drive_backup_sub': {
      AppLang.hinglish: 'Auto backup midnight 12 AM',
      AppLang.hindi: 'ऑटो बैकअप रात 12 बजे',
      AppLang.english: 'Auto backup at 12 AM midnight',
    },
    'app_language': {
      AppLang.hinglish: 'App Bhasha (Language)',
      AppLang.hindi: 'ऐप भाषा',
      AppLang.english: 'App Language',
    },
    'current_lang_label': {
      AppLang.hinglish: 'Current: Hinglish',
      AppLang.hindi: 'वर्तमान: हिंदी',
      AppLang.english: 'Current: English',
    },
    'dark_mode_theme': {
      AppLang.hinglish: 'Dark Mode Theme',
      AppLang.hindi: 'डार्क मोड थीम',
      AppLang.english: 'Dark Mode Theme',
    },
    'backend_server_ip': {
      AppLang.hinglish: 'Backend Server IP',
      AppLang.hindi: 'बैकएंड सर्वर IP',
      AppLang.english: 'Backend Server IP',
    },
    'logout': {
      AppLang.hinglish: 'Logout Karein',
      AppLang.hindi: 'लॉगआउट करें',
      AppLang.english: 'Logout',
    },
    'lang_changed_toast': {
      AppLang.hinglish: 'Bhasha badli: ',
      AppLang.hindi: 'भाषा बदली: ',
      AppLang.english: 'Language changed: ',
    },
  };

  /// Translate key according to current lang string ('Hinglish', 'हिंदी', 'English')
  static String tr(String key, String currentLang) {
    final lang = currentAppLang(currentLang);
    final entry = _dict[key];
    if (entry == null) return key;
    return entry[lang] ?? entry[AppLang.hinglish] ?? key;
  }
}
