const admin = require("firebase-admin");
const functions = require('firebase-functions');
const Stripe = require('stripe');

const stripeSecret = functions.config().stripe.secret;
const stripe = Stripe(stripeSecret);
admin.initializeApp();

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  console.log("Datos recibidos en createPaymentIntent:", data);
  console.log("Tipo de amount:", typeof data.amount);

  const amount = Number(data.amount);
  console.log("Amount convertido a Number:", amount);

  if (!amount || typeof amount !== 'number' || amount <= 0 || isNaN(amount)) {
    console.error("Parámetro 'amount' inválido o ausente:", data.amount);
    throw new functions.https.HttpsError(
      "invalid-argument",
      "El parámetro 'amount' es requerido y debe ser un número positivo."
    );
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: "eur",
      automatic_payment_methods: { enabled: true },
    });

    console.log("PaymentIntent creado correctamente, id:", paymentIntent.id);

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (e) {
    console.error("Error creando PaymentIntent:", e);
    throw new functions.https.HttpsError("internal", e.message);
  }
});
