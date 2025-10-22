# Script de déploiement local (à créer sur votre PC)
#!/bin/bash
echo "🚀 DÉPLOIEMENT LOCAL depuis Harbor..."

# 1. Récupérer les images depuis Harbor
docker pull harbor.local:8080/workflow/backend:latest
docker pull harbor.local:8080/workflow/frontend:latest

# 2. Arrêter l'ancienne version
docker compose down

# 3. Lancer la nouvelle version
docker compose up -d

# 4. Vérification
echo "⏳ Attente du démarrage..."
sleep 10

echo "✅ DÉPLOIEMENT LOCAL RÉUSSI!"
echo "🌐 ACCÈS :"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend:  http://localhost:5000"
echo "   - Health:   http://localhost:5000/health"

# Test
curl -f http://localhost:5000/health && echo "✅ Backend OK" || echo "❌ Backend KO"