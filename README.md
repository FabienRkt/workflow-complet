# I. Prérequis obligatoires

  1.1 GitLab local fonctionnel
  
    Votre instance GitLab doit être opérationnelle (HTTP ou HTTPS).
  
  1.2 Harbor installé et accessible
  
    Votre registre Harbor doit être joignable, par exemple :
  
    http://harbor.local:8080
  
    Le projet Harbor doit exister : workflow
  
  1.3 Autoriser GitLab à communiquer avec Harbor (important)
  
    Dans GitLab Admin Area :
  
    Admin Area → Settings → Network → Outbound Requests
    
    Cocher :
      - Allow requests to the local network from webhooks and integrations
      - Allow requests to the local network from system hooks
      - Allow requests to local addresses
  
    Cela permet à GitLab de contacter Harbor en HTTP (sinon Docker login échoue dans le pipeline).
  
  1.4 Intégration GitLab ↔ Harbor
  
    Dans votre projet GitLab :
    
    Settings → Integrations → Harbor
    
    Configurer :
      - Harbor URL : http://harbor.local:8080
      - Project : workflow
      - Username : <compte harbor>
      - Password : <password harbor>
  
    Cela permet le push automatique des images vers Harbor.

  1.5 Variables CI/CD nécessaires

    À ajouter dans GitLab → Settings → CI/CD → Variables.
    
    Nom variable	          Description
    CI_HARBOR_USER	        Utilisateur Harbor
    CI_HARBOR_PASSWORD	    Mot de passe Harbor
    TWILIO_ACCOUNT_SID	    Identifiant Twilio
    TWILIO_AUTH_TOKEN	    Token Twilio
    TWILIO_WHATSAPP_FROM	Numéro WhatsApp Twilio
    TWILIO_WHATSAPP_TO	    Destinataire WhatsApp

II. Configuration obligatoire des GitLab Runners

  Le pipeline utilise deux runners :
  
  Runner 1 — “workflow”
  
  utilisé pour : build, scan, tests  
  exécuteur Docker-in-Docker (dind)
  
  Configuration complète :
  
  ```toml
  [[runners]]
    name = "workflow"
    url = "http://gitlab.local:8081"
    id = 2
    token = "glrt-w6MK7xXyZzMYA7FkyP71G86MQpwOjMKdDozCnU6MQ8.01.170f6cdxj"
    executor = "docker"
  
    [runners.cache]
      MaxUploadedArchiveSize = 0
  
    [runners.docker]
      tls_verify = false
      image = "docker:latest"
      privileged = true
      disable_entrypoint_overwrite = false
      oom_kill_disable = false
      disable_cache = false
      volumes = ["/cache"]
      extra_hosts = ["harbor.local:192.168.88.15"]
      network_mode = "network-git"
  ```
  
  Remarques :
  - privileged = true est obligatoire pour Docker-in-Docker.
  - extra_hosts permet de résoudre harbor.local.
  - network_mode = "network-git" permet la communication runner ↔ GitLab ↔ Harbor.
  
  Runner 2 — “workflow-deploy”
  
  utilisé uniquement pour le déploiement sur la machine hôte  
  doit accéder au Docker de l’hôte via /var/run/docker.sock
  
  Configuration complète :
  
  ```toml
  [[runners]]
    name = "Runner déploiement Docker hôte"
    url = "http://gitlab.local:8081"
    id = 3
    token = "glrt-VN0O9bMtV-bT4gUv3EYdwG86MQpwOjMKdDozCnU6MQ8.01.171xpksgx"
    executor = "docker"
    tags = ["workflow-deploy"]
    run_untagged = false
    locked = false
  
    [runners.cache]
      MaxUploadedArchiveSize = 0
  
    [runners.docker]
      tls_verify = false
      image = "docker:24.0.5"
      privileged = false
      extra_hosts = [
        "harbor.local:192.168.88.15",
        "gitlab.local:192.168.88.15"
      ]
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock",
        "/cache"
      ]
  ```
  
  Remarques :
  - Ce runner déploie directement sur la machine hôte via Docker socket.
  - Pas de mode privilégié ici.
  - L’image Docker du runner peut utiliser docker compose.

III. Structure du projet

    workflow-complet/
    ├── .gitlab-ci.yml
    ├── docker-compose.yml
    ├── README.md
    ├── backend/
    │   ├── app.py
    │   ├── requirements.txt
    │   ├── Dockerfile
    │   └── test/
    │        └── test_app.py
    └── frontend/
        ├── src/index.js
        ├── package.json
        ├── Dockerfile
        └── test/app.test.js

IV. Fonctionnement complet du pipeline CI/CD

  1. precheck
   - Connexion à Harbor + vérification Docker.

  2. build_and_scan (backend + frontend)
   - construction des images
   - analyse Trivy pré-push
   - conversion JSON → CSV des vulnérabilités
   - push vers Harbor

  Trivy n’a pas besoin d’être installé localement — il est exécuté depuis l’image Docker officielle : aquasec/trivy:latest

  3. postscan
   - Analyse Trivy post-push, sur les images récupérées depuis Harbor.

  4. test
   - Lancement des tests unitaires :
     - Backend → pytest
     - Frontend → npm test

  5. deploy
   - Déploiement automatique en production :
     - arrêt des conteneurs
     - récupération des dernières images depuis Harbor
     - docker compose up -d
     - vérification des ports : 5000 (backend), 3000 (frontend)
   - Aucune action manuelle requise. Tout est automatisé.

  . notification
   - Envoi d’une notification WhatsApp via Twilio.

V. Lancer le projet après clonage

  Après avoir correctement configuré :
    - l’intégration GitLab ↔ Harbor
    - les runners
    - les autorisations réseau

  Il suffit de pousser une branche sur GitLab :
  
  ```sh
  git add .
  git commit -m "Initial commit"
  git push origin main
  ```

  Le pipeline se lance automatiquement : build → scan → push → tests → déploiement automatique → notification

VI. Objectif du projet

    Ce projet sert d’exemple complet de pipeline CI/CD professionnel :
      - orchestré entièrement par GitLab
      - compatible infrastructures locales sans TLS
      - avec analyses de sécurité avancées
      - avec déploiement automatique
