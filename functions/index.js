const { onCall } = require("firebase-functions/v2/https")
const admin = require("firebase-admin")

admin.initializeApp()

// Función para asignar roles a usuarios
exports.setUserRole = onCall(async (request) => {
  const { uid, role } = request.data

  // Verifica que quien llama sea un admin
  const callerClaims = request.auth && request.auth.token
  if (!callerClaims || callerClaims.role !== "admin") {
    throw new Error("No autorizado. Solo los administradores pueden asignar roles.")
  }

  // Asigna el rol como claim personalizado
  await admin.auth().setCustomUserClaims(uid, { role })

  return { message: `Rol ${role} asignado al usuario ${uid}` }
})

// Función para asignar el primer administrador (solo se debe ejecutar una vez)
exports.setFirstAdmin = onCall(async () => {
  const uid = "TIio7tYmW2SiE8X114tZ0pI8Cd82" // ID del usuario que será admin

  try {
    // Asigna el rol de admin
    await admin.auth().setCustomUserClaims(uid, { role: "admin" })
    return { success: true, message: `Usuario ${uid} configurado como administrador` }
  } catch (error) {
    console.error("Error al asignar rol de administrador:", error)
    return { success: false, error: error.message }
  }
})
