/**
 * Import function triggers from their respective submodules:
 */
const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const nodemailer = require("nodemailer");
const {initializeApp} = require("firebase-admin/app");
const admin = require("firebase-admin");
const {HttpsError} = require("firebase-functions/v2/https");

// Initialize Firebase Admin SDK
initializeApp();

// Initialize nodemailer transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "juclean988@gmail.com",
    pass: "fknp eufo jpjf wplh",
  },
});

// Set global options
setGlobalOptions({maxInstances: 10});

// Cloud Function to send push notification to admins
exports.sendTestNotification = onCall(
  {
    enforceAppCheck: false,
    consumeAppCheckToken: false,
  },
  async (request) => {
    try {


      const messaging = admin.messaging();

      // Send to a specific test device token
      const response = await messaging.send({
        token: "e-wKj2BjSXC5R5EnZop85h:APA91bGqlb2ICfO5WGfgsasSveKMDxDoNk0LKgMl1WpFisbE-yiNahk7c6b9r4OnBIB2Kr5YMEDRBKt2FJTpBIZn2EgPWihVaYVAXWvpKAJUZ6s1FlC3Pe8",
        notification: {
          title: request.data.title || "New Booking Request",
          body: request.data.message || "You have new booking request from JUCLEAN",
        },
        android: {priority: "high"},
        apns: {headers: {"apns-priority": "10"}},
      });

      console.log("Test notification sent successfully:", response);
      return {success: true, messageId: response};
    } catch (error) {
      console.error("Error sending test notification:", error);
      throw new HttpsError("internal", "Failed to send test notification", error.message);
    }
  },
);

exports.sendTestNotification1 = onCall(
  {
    enforceAppCheck: false,
    consumeAppCheckToken: false,
  },
  async (request) => {
    try {


      const messaging = admin.messaging();

      // Send to a specific test device token
      const response = await messaging.send({
        token: "f-h1M75RR7Oh1FIZorF7gW:APA91bHJovNp1C74fqs1LTf7blTuzklfInxt9fFwC5aqYnBrUcTyN1VS39aoDsKo4xpT2Cq1Po2iMs6yATx59WglMNABoP1hS2RXNbZhLXeHmfRAoY8grv8",
        notification: {
          title: request.data.title || "New Booking Request",
          body: request.data.message || "You have new booking request from JUCLEAN",
        },
        android: {priority: "high"},
        apns: {headers: {"apns-priority": "10"}},
      });

      console.log("Test notification sent successfully:", response);
      return {success: true, messageId: response};
    } catch (error) {
      console.error("Error sending test notification:", error);
      throw new HttpsError("internal", "Failed to send test notification", error.message);
    }
  },
);

exports.sendAdminNotification = onCall(
  {
    enforceAppCheck: false, // Disable App Check validation
    consumeAppCheckToken: false,
  },
  async (data, context) => {
    console.log("Request received:", JSON.stringify({
      data,
      auth: context.auth ? {
        uid: context.auth.uid,
        email: context.auth.token.email,
      } : null,
      timestamp: new Date().toISOString(),
    }));

    try {
      // Validate input data
      if (!data.orderId || !data.serviceName) {
        throw new HttpsError("invalid-argument", "Missing required fields");
      }

      // Get services with error handling
      const firestore = admin.firestore();
      const messaging = admin.messaging();

      // Add transaction for reliability
      return await firestore.runTransaction(async (transaction) => {
        const adminsRef = firestore.collection("admins");
        const adminsSnapshot = await transaction.get(adminsRef);

        const messages = [];
        const batch = firestore.batch();

        for (const adminDoc of adminsSnapshot.docs) {
          const devicesRef = adminDoc.ref.collection("devices");
          const devicesSnapshot = await transaction.get(devicesRef);

          devicesSnapshot.forEach((deviceDoc) => {
            const token = deviceDoc.data().token;
            if (token && typeof token === "string") {
              messages.push({
                token: token,
                notification: {
                  title: `New Booking: ${data.orderId}`,
                  body: `Service: ${data.serviceName}`,
                },
                android: {priority: "high"},
                apns: {headers: {"apns-priority": "10"}},
              });

              // Update last used timestamp
              batch.update(deviceDoc.ref, {
                lastUsed: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          });
        }

        if (messages.length === 0) {
          console.warn("No valid devices found");
          return {success: false, message: "No active devices"};
        }

        try {
          // Send notifications
          const response = await messaging.sendAll(messages);
          await batch.commit();

          console.log(`Successfully sent ${response.successCount} messages`);
          return {
            success: true,
            sentCount: response.successCount,
            failedCount: response.failureCount,
          };
        } catch (sendError) {
          console.error("Message sending failed:", sendError);
          throw new HttpsError("internal", "Notification delivery failed");
        }
      });
    } catch (error) {
      console.error("COMPLETE FAILURE:", {
        error: error.message,
        stack: error.stack,
        raw: error,
      });

      // Convert generic errors to HttpsError
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Operation failed", {
        originalError: error.message,
        timestamp: new Date().toISOString(),
      });
    }
  },
);



exports.sendTestNotificationMaterial = onCall(
  {
    enforceAppCheck: false,
    consumeAppCheckToken: false,
  },
  async (request) => {
    try {


      const messaging = admin.messaging();

      // Send to a specific test device token
      const response = await messaging.send({
        token: "e-wKj2BjSXC5R5EnZop85h:APA91bGqlb2ICfO5WGfgsasSveKMDxDoNk0LKgMl1WpFisbE-yiNahk7c6b9r4OnBIB2Kr5YMEDRBKt2FJTpBIZn2EgPWihVaYVAXWvpKAJUZ6s1FlC3Pe8",
        notification: {
          title: request.data.title || "New Material Request",
          body: request.data.message || "You have new material request from JUCLEAN",
        },
        android: {priority: "high"},
        apns: {headers: {"apns-priority": "10"}},
      });

      console.log("Test notification sent successfully:", response);
      return {success: true, messageId: response};
    } catch (error) {
      console.error("Error sending test notification:", error);
      throw new HttpsError("internal", "Failed to send test notification", error.message);
    }
  },
);

exports.sendTestNotificationMaterial1 = onCall(
  {
    enforceAppCheck: false,
    consumeAppCheckToken: false,
  },
  async (request) => {
    try {


      const messaging = admin.messaging();

      // Send to a specific test device token
      const response = await messaging.send({
        token: "f-h1M75RR7Oh1FIZorF7gW:APA91bHJovNp1C74fqs1LTf7blTuzklfInxt9fFwC5aqYnBrUcTyN1VS39aoDsKo4xpT2Cq1Po2iMs6yATx59WglMNABoP1hS2RXNbZhLXeHmfRAoY8grv8",
        notification: {
          title: request.data.title || "New Material Request",
          body: request.data.message || "You have new material request from JUCLEAN",
        },
        android: {priority: "high"},
        apns: {headers: {"apns-priority": "10"}},
      });

      console.log("Test notification sent successfully:", response);
      return {success: true, messageId: response};
    } catch (error) {
      console.error("Error sending test notification:", error);
      throw new HttpsError("internal", "Failed to send test notification", error.message);
    }
  },
);

// Cloud Function to send email
exports.sendEmail = onCall(async (request) => {
  try {
    const mailOptions = {
      from: "JUCLEAN <juclean988@gmail.com>",
      to: request.data.to,
      subject: request.data.subject,
      html: request.data.html,
    };

    await transporter.sendMail(mailOptions);
    return {success: true};
  } catch (error) {
    console.error("Email sending failed:", error);
    throw new HttpsError("internal", "Failed to send email", error.message);
  }
});