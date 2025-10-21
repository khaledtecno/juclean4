import 'dart:math';

import 'package:translator_plus/translator_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class FastTranslationService {
  static final GoogleTranslator _translator = GoogleTranslator();
  static Map<String, String> _translationCache = {};
  static bool _isMalay = false;

  static final Map<String, String> _translationMap = {
    // Profile Screen
    'Information': 'Informationen',
    'Customer': 'Kunde',


    // New translations from DetailServiceEmployee
    'Error loading tools: \$e': 'Fehler beim Laden der Werkzeuge: \$e',
    'You must be logged in to update bookings': 'Sie müssen angemeldet sein, um Buchungen zu aktualisieren',
    'Please provide your contact information': 'Bitte geben Sie Ihre Kontaktinformationen an',
    'User details not found': 'Benutzerdetails nicht gefunden',
    'Booking \$newStatus successfully': 'Buchung erfolgreich \$newStatus',
    'Failed to update booking: \$e': 'Fehler beim Aktualisieren der Buchung: \$e',
    'Could not open map: \$e': 'Karte konnte nicht geöffnet werden: \$e',
    // New translations from EmployeeHome
    'Employee Home': 'Mitarbeiter Startseite',
    'Ready to work today?': 'Bereit für die Arbeit heute?',
    'No service selected': 'Kein Service ausgewählt',
    'Failed to save service selection: \$e': 'Fehler beim Speichern der Serviceauswahl: \$e',
    'Current Service': 'Aktueller Service',
    'SELECTED SERVICE': 'AUSGEWÄHLTER SERVICE',
    'Change Service': 'Service ändern',
    'My Bookings': 'Meine Buchungen',
    'No Bookings Found': 'Keine Buchungen gefunden',
    'When you book a service, it will appear here': 'Wenn Sie einen Service buchen, wird er hier angezeigt',
    'Book a Service': 'Service buchen',
    'No matching bookings': 'Keine passenden Buchungen',
    'Try adjusting your filters or search': 'Versuchen Sie Ihre Filter oder Suche anzupassen',
    'View Details': 'Details anzeigen',
    'Pending': 'Ausstehend',
    'Confirmed': 'Bestätigt',
    'Completed': 'Abgeschlossen',
    'Cancelled': 'Storniert',
    'Unknown': 'Unbekannt',
    'Error loading bookings': 'Fehler beim Laden der Buchungen',
    'Select a Service': 'Service auswählen',
    'No services available': 'Keine Services verfügbar',
    'Close': 'Schließen',
    'Failed to update status: \${e.toString()}': 'Fehler beim Aktualisieren des Status: \${e.toString()}',
    'Confirm Logout': 'Abmeldung bestätigen',
    'Are you sure you want to log out?': 'Möchten Sie sich wirklich abmelden?',
    'No': 'Nein',
    'Yes': 'Ja',
    'All': 'Alle',
    'Hello there,': 'Hallo,',
    'Recently (history)': 'Kürzlich (Verlauf)',
    'See All': 'Alle anzeigen',
    'Cleaning house': 'Hausreinigung',
    'Cleaning Villa': 'Villenreinigung',
    'Paid:': 'Bezahlt:',
    'Click for more details': 'Für Details klicken',
    'Booking status updated to \$newStatus': 'Buchungsstatus aktualisiert auf \$newStatus',
    'Failed to update booking: \$e': 'Fehler beim Aktualisieren der Buchung: \$e',
    'Could not open map': 'Karte konnte nicht geöffnet werden',
    'Retry': 'Erneut versuchen',
    'Notes': 'Notizen',
    'Address': 'Adresse',
    'View on Map': 'Auf Karte anzeigen',
    'Accept': 'Annehmen',
    'Reject': 'Ablehnen',
    'Mark as Completed': 'Als abgeschlossen markieren',
    'ONLINE': 'ONLINE',
    'OFFLINE': 'OFFLINE',
    'Unknown Service': 'Unbekannter Service',
    'My Works': 'Meine Aufträge',
    'Search jobs, clients...': 'Aufträge, Kunden suchen...',
    'All': 'Alle',
    'Pending': 'Ausstehend',
    'Confirmed': 'Bestätigt',
    'Completed': 'Abgeschlossen',
    'Cancelled': 'Storniert',
    'Unknown': 'Unbekannt',
    'Error loading bookings': 'Fehler beim Laden der Buchungen',
    'No bookings found for your account': 'Keine Buchungen für Ihr Konto gefunden',
    'No matching bookings': 'Keine passenden Buchungen',
    'Try adjusting your filters or search': 'Passen Sie Ihre Filter oder Suche an',
    'Clear filters': 'Filter zurücksetzen',
    'View Details': 'Details anzeigen',
    'Advanced Filters': 'Erweiterte Filter',
    'Price Range': 'Preisspanne',
    'Date Range': 'Zeitraum',
    'Service Type': 'Servicetyp',
    'User': 'Benutzer',
    'Employee': 'Mitarbeiter',
    'Type of user': 'Benutzertyp',
    'Works Done': 'Erledigte Arbeiten',
    'Address': 'Adresse',
    'Show address': 'Adresse anzeigen',
    'Tasks': 'Aufgaben',
    'Show your done, waiting tasks': 'Abgeschlossene und wartende Aufgaben anzeigen',
    'Saved': 'Gespeichert',
    'Show saved services': 'Gespeicherte Dienstleistungen anzeigen',
    'Last 30 days': 'Letzte 30 Tage',
    'All Services': 'Alle Services',
    'Apply Filters': 'Filter anwenden',
    'Book Again': 'Erneut buchen',
    'Unknown Service': 'Unbekannter Service',
    'No address provided': 'Keine Adresse angegeben',

    // Status-related translations
    'pending': 'ausstehend',
    'confirmed': 'bestätigt',
    'completed': 'abgeschlossen',
    'cancelled': 'storniert',

    // Date/time formats
    'MMM dd, yyyy': 'dd. MMM yyyy', // German date format
    'hh:mm a': 'HH:mm',
    'No address provided': 'Keine Adresse angegeben',
    'No description': 'Keine Beschreibung',
    'No name': 'Kein Name',

    // Status-related translations
    'pending': 'ausstehend',
    'confirmed': 'bestätigt',
    'completed': 'abgeschlossen',
    'cancelled': 'storniert',

    // Time/Date formats
    'h:mm a • MMM d, y': 'HH:mm • d. MMM y', // German time/date format
    'MMM dd, yyyy': 'dd. MMM yyyy',
    'Location services are disabled': 'Standortdienste sind deaktiviert',
    'Location permissions are denied': 'Standortberechtigungen wurden verweigert',
    'Location permissions are permanently denied': 'Standortberechtigungen wurden dauerhaft verweigert',
    'Error checking distance: \$e': 'Fehler bei der Entfernungsprüfung: \$e',
    'Location is too far (\${distanceInMeters.toString()} meters)': 'Standort ist zu weit entfernt (\${distanceInMeters.toString()} Meter)',

    // UI Elements
    'Service Details': 'Service-Details',
    'CLIENT INFORMATION': 'KUNDENINFORMATION',
    'No phone provided': 'Keine Telefonnummer angegeben',
    'No email provided': 'Keine E-Mail angegeben',
    'BOOKING DETAILS': 'BUCHUNGSDETAILS',
    'Date': 'Datum',
    'Time': 'Uhrzeit',
    'Address': 'Adresse',
    'No address provided': 'Keine Adresse angegeben',
    'Show in map': 'In Karte anzeigen',
    'CUSTOMER NOTES': 'KUNDENNOTIZEN',
    'TOOLS REQUIRED': 'BENÖTIGTE WERKZEUGE',
    'Select tools and quantities you will need for this service:': 'Wählen Sie die Werkzeuge und Mengen aus, die Sie für diesen Service benötigen:',
    'No tools available': 'Keine Werkzeuge verfügbar',
    'Quantity': 'Menge',
    'YOUR CONTACT INFORMATION': 'IHRE KONTAKTINFORMATIONEN',
    'Your Phone Number': 'Ihre Telefonnummer',
    'Enter your contact number': 'Geben Sie Ihre Kontaktnummer ein',
    'Preferred Contact Method': 'Bevorzugte Kontaktmethode',
    'e.g., WhatsApp, SMS, Call': 'z.B. WhatsApp, SMS, Anruf',
    'ACCEPT BOOKING': 'BUCHUNG ANNEHMEN',
    'MARK AS COMPLETED': 'ALS ABGESCHLOSSEN MARKIEREN',

    // Statuses
    'pending': 'ausstehend',
    'confirmed': 'bestätigt',
    'completed': 'abgeschlossen',
    'cancelled': 'storniert',
    'Unknown Service': 'Unbekannter Service',
    'Unknown Employee': 'Unbekannter Mitarbeiter',
    'Unknown Customer': 'Unbekannter Kunde',

    // Distance messages
    'Checking Distance...': 'Entfernung wird geprüft...',
    'Check Distance': 'Entfernung prüfen',
    'Location is within acceptable range (1-150m)': 'Standort liegt im akzeptablen Bereich (1-150m)',
    'Location is too far from service area': 'Standort ist zu weit vom Servicebereich entfernt',
    'meters away': 'Meter entfernt',
    'Type of user': 'Benutzertyp',
    'Orders Done': 'Erledigte Aufträge',
    'Change to Germany': 'Sprache auf Deutsch umstellen',
    'Saved': 'Gespeichert',
    'Show saved services': 'Gespeicherte Dienste anzeigen',
    'Dashboard': 'Dashboard',
    'User Management': 'Benutzerverwaltung',
    'Employee Management': 'Mitarbeiterverwaltung',
    'Order Management': 'Bestellverwaltung',
    'Analytics': 'Analysen',
    'Add materials': 'Materialien hinzufügen',
    'Send Emails': 'E-Mails senden',
    'Analytics Material': 'Materialanalysen',
    'Services': 'Dienstleistungen',
    'Logout': 'Abmelden',
    'Logout Confirmation': 'Bestätigung der Abmeldung',
    'Are you sure you want to logout?': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
    'Cancel': 'Abbrechen',
    'Logout error: ': 'Abmeldefehler: ',
    'Welcome back,': 'Willkommen zurück,',
    'Neo Admin Dashboard': 'Neo Admin Dashboard',
    'Everything you need to manage your platform.': 'Alles, was Sie benötigen, um Ihre Plattform zu verwalten.',
    'Total Users': 'Benutzer insgesamt',
    'Tool Usage History & Analytics': 'Werkzeugnutzungshistorie & Analysen',
    'Usage History': 'Nutzungshistorie',
    'Analytics': 'Analysen',
    'Total Usage': 'Gesamtnutzung',
    'items': 'Artikel',
    'Tools Used': 'Verwendete Werkzeuge',
    'tools': 'Werkzeuge',
    'Employees': 'Mitarbeiter',
    'people': 'Personen',
    'Date Range': 'Zeitraum',
    'No records found for selected filters': 'Keine Datensätze für ausgewählte Filter gefunden',
    'Booking #': 'Buchung Nr.',
    'No data available for charts': 'Keine Daten für Diagramme verfügbar',
    'Filter History': 'Historie filtern',
    'All Tools': 'Alle Werkzeuge',
    'Filter by Tool': 'Nach Werkzeug filtern',
    'All Employees': 'Alle Mitarbeiter',
    'Filter by Employee': 'Nach Mitarbeiter filtern',
    'Reset Filters': 'Filter zurücksetzen',
    'Close': 'Schließen',
    'Usage Details': 'Nutzungsdetails',
    'Tool Name': 'Werkzeugname',
    'Quantity Used': 'Verwendete Menge',
    'Employee': 'Mitarbeiter',
    'Employee Email': 'Mitarbeiter-E-Mail',
    'Booking ID': 'Buchungs-ID',
    'Service': 'Dienstleistung',
    'Home': 'Startseite',
    'Hi,': 'Hallo,',
    'User': 'Benutzer',
    'The best cleaning services for you.': 'Die besten Reinigungsservices für Sie.',
    'Search for services...': 'Nach Services suchen...',
    'Here you can Search for service': 'Hier können Sie nach Services suchen',
    'Popular Services': 'Beliebte Services',
    'Recent Services': 'Letzte Services',
    'See All': 'Alle anzeigen',
    'No services available': 'Keine Services verfügbar',
    'View Details': 'Details anzeigen',
    'Book Now': 'Jetzt buchen',
    'Deep Clean': 'Grundreinigung',
    'From \$120': 'Ab 120€',
    '3-5 hours': '3-5 Stunden',
    'Office Clean': 'Büroreinigung',
    'From \$200': 'Ab 200€',
    '5-8 hours': '5-8 Stunden',
    'Carpet Clean': 'Teppichreinigung',
    'From \$150': 'Ab 150€',
    '2-4 hours': '2-4 Stunden',
    'My Booking': 'Meine Buchungen',
    'Profile': 'Profil',
    'Logout': 'Abmelden',
    'Logout Confirmation': 'Abmeldebestätigung',
    'Are you sure you want to logout?': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
    'Cancel': 'Abbrechen',
    'Logout error: ': 'Abmeldefehler: ',
    'Contact Us': 'Kontaktieren Sie uns',
    'Email Support': 'E-Mail-Support',
    'WhatsApp Chat': 'WhatsApp-Chat',
    'JUClean Support Request': 'JUClean Support-Anfrage',
    'Hello JUClean team,': 'Hallo JUClean Team,',
    'WhatsApp not installed': 'WhatsApp nicht installiert',
    'Could not launch email client': 'E-Mail-Client konnte nicht geöffnet werden',
    'Here you can see all services available': 'Hier sehen Sie alle verfügbaren Services',

    // Profile Screen
    'Information': 'Informationen',
    'Customer': 'Kunde',
    'Type of user': 'Benutzertyp',
    'Customer Email': 'Kunden-E-Mail',
    'Date': 'Datum',

    // Profile Screen
    'Information': 'Informationen',
    'Customer': 'Kunde',
    'Type of user': 'Benutzertyp',
    'Employees': 'Mitarbeiter',
    'Bookings': 'Buchungen',
    'View all': 'Alle anzeigen',
    'Quick Actions': 'Schnellaktionen',
    'Add User': 'Benutzer hinzufügen',
    'New Material': 'Neues Material',
    'Add Employee': 'Mitarbeiter hinzufügen',
    'Generate Report': 'Bericht erstellen',
    'Tap to create': 'Zum Erstellen tippen',
    'Manage Users': 'Benutzer verwalten',
    'Process Orders': 'Bestellungen bearbeiten',
    'Logout Account': 'Konto abmelden',

    // Profile Screen
    'Information': 'Informationen',
    'Customer': 'Kunde',
    'Type of user': 'Benutzertyp',
    // Additional Sections
    'Address': 'Adresse',
    'Show address': 'Adresse anzeigen',
    'Tasks': 'Aufgaben',
    'Show your done, waiting tasks': 'Erledigte und ausstehende Aufgaben anzeigen',
    'Home': 'Startseite',
    'Hi,': 'Hallo!',
    'Wo Reinheit beginnt - und Eindruck bleibt': 'Wo Reinheit beginnt - und Eindruck bleibt.',
    'Search for services...': 'Nach Diensten suchen...',
    'Popular Services': 'Beliebte Dienste',
    'Deep Clean': 'Tiefenreinigung',
    'From \$120': 'Ab 120 \$',
    '3-5 hours': '3–5 Stunden',
    'Office Clean': 'Büroreinigung',
    'From \$200': 'Ab 200 \$',
    '5-8 hours': '5–8 Stunden',
    'Carpet Clean': 'Teppichreinigung',
    'From \$150': 'Ab 150 \$',
    '2-4 hours': '2–4 Stunden',
    'Book Now': 'Jetzt buchen',
    'Recent Services': 'Kürzlich gebuchte Dienste',
    'See All': 'Alle anzeigen',
    'No services available': 'Keine Dienste verfügbar',
    'View Details': 'Details anzeigen',

    // Bottom Navigation
    'My Booking': 'Meine Buchungen',
    'Profile': 'Profil',

    // Logout Dialog
    'Logout Confirmation': 'Abmeldebestätigung',
    'Are you sure you want to logout?': 'Möchten Sie sich wirklich abmelden?',
    'Cancel': 'Abbrechen',
    'Logout': 'Abmelden',

    // Booking/Service Details
    'rooms': 'Räume',
    'additional': 'Zusätzlich',
    'Add New Address': 'Neue Adresse hinzufügen',
    'Address Details': 'Adressdetails',
    'Address Name (e.g., My Home)': 'Adressname (z.B. Zuhause)',
    'Please give this address a name': 'Bitte geben Sie dieser Adresse einen Namen',
    'Address Type': 'Adresstyp',
    'Please select address type': 'Bitte wählen Sie einen Adresstyp',
    'Full Address': 'Vollständige Adresse',
    'Please enter your address': 'Bitte geben Sie Ihre Adresse ein',
    'Google Maps Link (Optional)': 'Google-Maps-Link (optional)',
    'Location Services': 'Standortdienste',
    'Use Current Location': 'Aktuellen Standort verwenden',
    'Current Location Coordinates': 'Koordinaten des aktuellen Standorts',
    'SAVE ADDRESS': 'ADRESSE SPEICHERN',

    // Address Types
    'Home': 'Zuhause',
    'Work': 'Arbeit',
    'Other': 'Andere',

    // Location Messages
    'Location obtained successfully': 'Standort erfolgreich ermittelt',
    'Error getting location:': 'Fehler beim Ermitteln des Standorts:',
    'Please sign in to save addresses': 'Bitte melden Sie sich an, um Adressen zu speichern',

    // Save Messages
    'Address saved successfully': 'Adresse erfolgreich gespeichert',
    'Failed to save address:': 'Fehler beim Speichern der Adresse:',

    // Coordinates
    'Lat:': 'Breitengrad:',
    'Lng:': 'Längengrad:',

    'My Addresses': 'Meine Adressen',
    'Add new address': 'Neue Adresse hinzufügen',

    // Authentication
    'Sign In to Manage Addresses': 'Melden Sie sich an, um Adressen zu verwalten',
    'Sign In': 'Anmelden',

    // Error States
    'Error loading addresses': 'Fehler beim Laden der Adressen',
    'Retry': 'Erneut versuchen',

    // Empty State
    'No Addresses Saved Yet': 'Noch keine Adressen gespeichert',
    'Tap the + button to add your first address': 'Tippen Sie auf +, um Ihre erste Adresse hinzuzufügen',
    'Add Address': 'Adresse hinzufügen',

    // Address Card
    'View on Map': 'Auf Karte anzeigen',

    // Delete Dialog
    'Delete Address?': 'Adresse löschen?',
    'Cancel': 'Abbrechen',
    'Delete': 'Löschen',

    // Success/Error Messages
    'Address deleted successfully': 'Adresse erfolgreich gelöscht',
    'Failed to delete address': 'Adresse konnte nicht gelöscht werden',
    'Could not open map': 'Karte konnte nicht geöffnet werden',
    'Book Service': 'Dienst buchen',
    'Select Date & Time': 'Datum und Uhrzeit wählen',
    'Select Date': 'Datum auswählen',
    'Select Time': 'Uhrzeit auswählen',
    'Cleaning Location': 'Reinigungsort',
    'Select Location on Map': 'Ort auf Karte auswählen',
    'Selected Location:': 'Ausgewählter Ort:',
    'Loading address...': 'Adresse wird geladen...',
    'Change Location': 'Ort ändern',
    'Additional Notes': 'Zusätzliche Hinweise',
    'Any special instructions for the cleaner...': 'Besondere Hinweise für die Reinigungskraft...',
    'Booking Summary': 'Buchungsübersicht',
    'Service': 'Dienstleistung',
    'Price': 'Preis',
    'Date': 'Datum',
    'Time': 'Uhrzeit',
    'Location': 'Ort',
    'Total': 'Gesamt',
    'Confirm Booking': 'Buchung bestätigen',

    // Map Selection Screen
    'Select Pickup Location': 'Abholort auswählen',
    'Search location...': 'Ort suchen...',
    'Selected Location:': 'Ausgewählter Ort:',
    'Fetching address...': 'Adresse wird abgerufen...',

    // New translations from extracted_strings.txt
    'Actions': 'Aktionen',
    'All Bookings': 'Alle Buchungen',
    'All Employees': 'Alle Mitarbeiter',
    'All Tools': 'Alle Werkzeuge',
    'An unexpected error occurred': 'Ein unerwarteter Fehler ist aufgetreten',
    'Are you sure you want to delete this service?': 'Möchten Sie diesen Dienst wirklich löschen?',
    'Are you sure you want to log out?': 'Möchten Sie sich wirklich abmelden?',
    'Authentication error: ${e.toString()}': 'Authentifizierungsfehler: ${e.toString()}',
    'Booking Date': 'Buchungsdatum',
    'Booking submitted successfully!': 'Buchung erfolgreich übermittelt!',
    'Bookings by Status': 'Buchungen nach Status',
    'CLOSE': 'SCHLIESSEN',
    'Cancel Order': 'Bestellung stornieren',
    'Cancelled': 'Storniert',
    'Category': 'Kategorie',
    'Check your inbox for verification link.': 'Überprüfen Sie Ihren Posteingang auf den Bestätigungslink.',
    'Close': 'Schließen',
    'Completed': 'Abgeschlossen',
    'Confirm': 'Bestätigen',
    'Confirm Logout': 'Abmeldung bestätigen',
    'Confirmed': 'Bestätigt',
    'Contact Link': 'Kontaktlink',
    'Contact information not available yet': 'Kontaktinformationen noch nicht verfügbar',
    'Could not launch email client': 'E-Mail-Client konnte nicht gestartet werden',
    'Could not open map: $e': 'Karte konnte nicht geöffnet werden: $e',
    'Could not send verification email.': 'Bestätigungs-E-Mail konnte nicht gesendet werden.',
    'Customer': 'Kunde',
    'Date Range': 'Datumsbereich',
    'Delete Service': 'Dienst löschen',
    'Edit Order': 'Bestellung bearbeiten',
    'Email': 'E-Mail',
    'Email Not Verified': 'E-Mail nicht verifiziert',
    'Email Sent': 'E-Mail gesendet',
    'Email Support': 'E-Mail-Support',
    'Email Verification': 'E-Mail-Bestätigung',
    'Email Verification Required': 'E-Mail-Bestätigung erforderlich',
    'Email sent successfully': 'E-Mail erfolgreich gesendet',
    'Error adding material: $e': 'Fehler beim Hinzufügen des Materials: $e',
    'Error checking distance: $e': 'Fehler beim Überprüfen der Entfernung: $e',
    'Error checking user role: ${e.toString()}': 'Fehler beim Überprüfen der Benutzerrolle: ${e.toString()}',
    'Error deleting material: $e': 'Fehler beim Löschen des Materials: $e',
    'Error deleting user: $e': 'Fehler beim Löschen des Benutzers: $e',
    'Error fetching locations: ${e.toString()}': 'Fehler beim Abrufen von Standorten: ${e.toString()}',
    'Error getting location: $e': 'Fehler beim Abrufen des Standorts: $e',
    'Error loading bookings': 'Fehler beim Laden der Buchungen',
    'Error loading saved services': 'Fehler beim Laden der gespeicherten Dienste',
    'Error loading tools: $e': 'Fehler beim Laden der Werkzeuge: $e',
    'Error searching locations: $e': 'Fehler beim Suchen von Standorten: $e',
    'Error searching locations: ${e.toString()}': 'Fehler beim Suchen von Standorten: ${e.toString()}',
    'Error selecting location': 'Fehler beim Auswählen des Standorts',
    'Error selecting location: $e': 'Fehler beim Auswählen des Standorts: $e',
    'Error submitting booking: $e': 'Fehler beim Übermitteln der Buchung: $e',
    'Error updating material: $e': 'Fehler beim Aktualisieren des Materials: $e',
    'Error updating user type: $e': 'Fehler beim Aktualisieren des Benutzertyps: $e',
    'Error: ${e.toString()}': 'Fehler: ${e.toString()}',
    'Error: ': 'Fehler: ',
    'Excel exported successfully': 'Excel erfolgreich exportiert',
    'Export as Excel': 'Als Excel exportieren',
    'Export as PDF': 'Als PDF exportieren',
    'Export failed: ${e.toString()}': 'Export fehlgeschlagen: ${e.toString()}',
    'Failed': 'Fehlgeschlagen',
    'Failed to delete service: $e': 'Dienst konnte nicht gelöscht werden: $e',
    'Failed to get location details': 'Standortdetails konnten nicht abgerufen werden',
    'Failed to remove service': 'Dienst konnte nicht entfernt werden',
    'Failed to resend email': 'E-Mail konnte nicht erneut gesendet werden',
    'Failed to save address: $e': 'Adresse konnte nicht gespeichert werden: $e',
    'Failed to save service selection: $e': 'Dienstauswahl konnte nicht gespeichert werden: $e',
    'Failed to send email: ${e.toString()}': 'E-Mail konnte nicht gesendet werden: ${e.toString()}',
    'Failed to send verification email': 'Bestätigungs-E-Mail konnte nicht gesendet werden',
    'Failed to update booking: $e': 'Buchung konnte nicht aktualisiert werden: $e',
    'Failed to update order: $error': 'Bestellung konnte nicht aktualisiert werden: $error',
    'Failed to update status: ${e.toString()}': 'Status konnte nicht aktualisiert werden: ${e.toString()}',
    'Failed: ${e.toString()}': 'Fehlgeschlagen: ${e.toString()}',
    'Fill All details': 'Alle Details ausfüllen',
    'Filter History': 'Verlauf filtern',
    'Generate Invoice': 'Rechnung generieren',
    'Generated on:': 'Generiert am: ',
    'Invoice Preview': 'Rechnungsvorschau',
    'Last Online': 'Zuletzt online',
    'Last Updated': 'Zuletzt aktualisiert',
    'Location is too far (${distanceInMeters} meters)': 'Standort ist zu weit (${distanceInMeters} Meter)',
    'Location obtained successfully': 'Standort erfolgreich ermittelt',
    'Location permissions are denied': 'Standortberechtigungen wurden verweigert',
    'Location permissions are permanently denied': 'Standortberechtigungen wurden dauerhaft verweigert',
    'Location services are disabled': 'Standortdienste sind deaktiviert',
    'Logout': 'Abmelden',
    'Create account' : 'Benutzerkonto erstellen',
    'Name':'Name',
    'Email':'E-Mail',

    'Do not have an account? Sign In':'Sie haben noch kein Konto? Anmelden',
    'SIGN UP USER':'BENUTZER ANMELDEN',
    'Forgot your password.':'Passwort vergessen.',
    'Sign In':'Anmelden',
    'Password':'Passwort',
    'Welcome to \nJUCleanApp' :'Willkommen bei\nJUCleanApp',
    'Logout error: $e': 'Abmeldefehler: $e',
    'Mark as Completed': 'Als abgeschlossen markieren',
    'Mark as In Progress': 'Als in Bearbeitung markieren',
    'Material deleted successfully': 'Material erfolgreich gelöscht',
    'Name': 'Name',
    'No': 'Nein',
    'SIGN UP' : 'MELDEN SIE SICH AN',
    'SIGN IN' : 'ANMELDEN',
    'No bookings found for your account': 'Keine Buchungen für Ihr Konto gefunden',
    'No data available for charts': 'Keine Daten für Diagramme verfügbar',
    'No matching services found.': 'Keine passenden Dienste gefunden.',
    'No orders found': 'Keine Bestellungen gefunden',
    'No records found for selected filters': 'Keine Datensätze für ausgewählte Filter gefunden',
    'No results found': 'Keine Ergebnisse gefunden',
    'No services available.': 'Keine Dienste verfügbar.',
    'No tools specified': 'Keine Werkzeuge angegeben',
    'OK': 'OK',
    'Open contact link': 'Kontaktlink öffnen',
    'Order ID': 'Bestellnummer',
    'Order deleted': 'Bestellung gelöscht',
    'Order deleted successfully': 'Bestellung erfolgreich gelöscht',
    'Order status updated ': 'Bestellstatus aktualisiert auf ',
    'Pending': 'Ausstehend',
    'Please enter email': 'Bitte E-Mail eingeben',
    'Please fill all fields': 'Bitte alle Felder ausfüllen',
    'Please provide your contact information': 'Bitte geben Sie Ihre Kontaktinformationen an',
    'Please select date, time, and location': 'Bitte Datum, Uhrzeit und Ort auswählen',
    'Please sign in to save addresses': 'Bitte melden Sie sich an, um Adressen zu speichern',
    'Please verify your email address before proceeding.': 'Bitte bestätigen Sie Ihre E-Mail-Adresse, bevor Sie fortfahren.',
    'Please verify your email before proceeding.': 'Bitte bestätigen Sie Ihre E-Mail, bevor Sie fortfahren.',
    'Price': 'Preis',
    'Quantity': 'Menge',
    'Resend Email': 'E-Mail erneut senden',
    'Resend email': 'E-Mail erneut senden',
    'Reset Filters': 'Filter zurücksetzen',
    'Reset email sent!': 'Passwort-Reset-E-Mail gesendet!',
    'Retry': 'Erneut versuchen',
    'Service': 'Dienstleistung',
    'Service deleted successfully': 'Dienst erfolgreich gelöscht',
    'Service removed from saved': 'Dienst aus den gespeicherten entfernt',
    'Sign In': 'Anmelden',
    'Sign-in Failed': 'Anmeldung fehlgeschlagen',
    'Status': 'Status',
    'Summary Statistics': 'Zusammenfassende Statistiken',
    'Template loaded into editor': 'Vorlage in Editor geladen',
    'This action cannot be undone.': 'Diese Aktion kann nicht rückgängig gemacht werden.',
    'Tool Usage History & Analytics': 'Werkzeugnutzungsverlauf & Analysen',
    'Type': 'Typ',
    'USE TEMPLATE': 'VORLAGE VERWENDEN',
    'Upload Image': 'Bild hochladen',
    'Usage Details': 'Nutzungsdetails',
    'Employee Home': 'Mitarbeiter Startseite',
    'ONLINE': 'ONLINE',
    'OFFLINE': 'OFFLINE',
    'Hello there,': 'Hallo,',
    'Ready to work today?': 'Bereit für die Arbeit heute?',
    'Recently (history)': 'Kürzlich (Verlauf)',
    'See All': 'Alle anzeigen',
    'Ahmed': 'Ahmed',
    'Cleaning house': 'Hausreinigung',
    'Ali': 'Ali',
    'Cleaning Villa': 'Villenreinigung',
    'Paid:': 'Bezahlt:',
    'Click for more details': 'Für Details klicken',
    'Current Service': 'Aktueller Service',
    'SELECTED SERVICE': 'AUSGEWÄHLTER SERVICE',
    'Change Service': 'Service ändern',
    'My Bookings': 'Meine Buchungen',
    'No Bookings Found': 'Keine Buchungen gefunden',
    'When you book a service, it will appear here': 'Wenn Sie einen Service buchen, erscheint er hier',
    'Book a Service': 'Service buchen',
    'No matching bookings': 'Keine passenden Buchungen',
    'Try adjusting your filters or search': 'Passen Sie Ihre Filter oder Suche an',
    'View Details': 'Details anzeigen',
    'Error loading bookings': 'Fehler beim Laden der Buchungen',
    'Pending': 'Ausstehend',
    'Confirmed': 'Bestätigt',
    'Completed': 'Abgeschlossen',
    'Cancelled': 'Storniert',
    'Unknown': 'Unbekannt',
    'Address': 'Adresse',
    'View on Map': 'Auf Karte anzeigen',
    'Notes': 'Notizen',
    'Accept': 'Annehmen',
    'Reject': 'Ablehnen',
    'Mark as Completed': 'Als abgeschlossen markieren',
    'Select a Service': 'Service auswählen',
    'No services available': 'Keine Services verfügbar',
    'Close': 'Schließen',
    'Confirm Logout': 'Abmeldung bestätigen',
    'Are you sure you want to log out?': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
    'No': 'Nein',
    'Yes': 'Ja',
    'Failed to update status:': 'Statusaktualisierung fehlgeschlagen:',
    'Could not open map': 'Karte konnte nicht geöffnet werden',
    'Retry': 'Erneut versuchen',
    'Failed to save service selection:': 'Serviceauswahl konnte nicht gespeichert werden:',
    'Booking status updated to': 'Buchungsstatus aktualisiert auf',
    'Failed to update booking:': 'Buchungsaktualisierung fehlgeschlagen:',

    // Profile Screen
    'Information': 'Informationen',
    'Customer': 'Kunde',
    'Type of user': 'Benutzertyp',
    'User details not found': 'Benutzerdetails nicht gefunden',
    'User type updated to ': 'Benutzertyp aktualisiert auf ',
    'Verification email resent': 'Bestätigungs-E-Mail erneut gesendet',
    'Verification email sent!': 'Bestätigungs-E-Mail gesendet!',
    'Verified': 'Verifiziert',
    'What would you like to edit?': 'Was möchten Sie bearbeiten?',
    'WhatsApp Chat': 'WhatsApp Chat',
    'WhatsApp not installed': 'WhatsApp nicht installiert',
    'Yes': 'Ja',
    'You must be logged in to update bookings': 'Sie müssen angemeldet sein, um Buchungen zu aktualisieren',
    '/hr': '/Std.'
  };

  static get distanceInMeters => null;

  static get error => null;

  // Initialize translation service
  static Future<void> init(bool isMalay) async {
    _isMalay = isMalay;
    if (!_isMalay) return;

    // Load from cache first
    await _loadFromCache();

    // Merge predefined translations with cached ones
    _translationCache.addAll(_translationMap);
    await _saveToCache();
  }

  static Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('translation_cache');
    if (cached != null) {
      _translationCache = Map<String, String>.from(json.decode(cached));
    }
  }

  static Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation_cache', json.encode(_translationCache));
  }

  // Main translation method - uses direct lookup first
  static String translate(String text) {
    if (!_isMalay) return text;

    // Check predefined translations first
    if (_translationMap.containsKey(text)) {
      return _translationMap[text]!;
    }

    // Fallback to cache
    return _translationCache[text] ?? text;
  }

  // For dynamic content not in predefined list
  static Future<String> translateDynamic(String text) async {
    if (!_isMalay) return text;

    // Check if we already have a translation
    final cached = translate(text);
    if (cached != text) return cached;

    try {
      // Fetch new translation
      final translation = await _translator.translate(text, to: 'de'); // Changed 'ms' to 'de'
      _translationCache[text] = translation.text;
      await _saveToCache();
      return translation.text;
    } catch (e) {
      print('Dynamic translation error: $e');
      return text;
    }
  }
}

Widget translatedtranslatedText(String text, {TextStyle? style}) {
  return Text(
    FastTranslationService.translate(text),
    style: style,
  );
}

