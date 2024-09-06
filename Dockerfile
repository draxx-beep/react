trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerImageName: 'my-react-app'
  dockerFilePath: 'Dockerfile'
  imageTarFile: 'my-react-app.tar'
  sshKeyFile: 'ssh_key'
  serverPath: '/path/to/save/docker-image.tar'

jobs:
- job: BuildAndDeploy
  steps:

    - task: Checkout@2
      inputs:
        repository: 'self'
        
    - task: NodeTool@0
      inputs:
        versionSpec: '18'
      displayName: 'Install Node.js'

    - script: |
        npm install
      displayName: 'Install dependencies'

    - script: |
        npm run build
      displayName: 'Build React app'

    - script: |
        docker build -t $(dockerImageName) .
      displayName: 'Build Docker image'

    - script: |
        docker save $(dockerImageName) -o $(imageTarFile)
      displayName: 'Save Docker image as artifact'

    - task: PublishPipelineArtifact@1
      inputs:
        targetPath: $(imageTarFile)
        artifactName: 'docker-image'
      displayName: 'Upload Docker image artifact'

    - task: DownloadPipelineArtifact@2
      inputs:
        artifactName: 'docker-image'
        downloadPath: '$(Pipeline.Workspace)'
      displayName: 'Download Docker image artifact'

    - script: |
        docker load -i $(Pipeline.Workspace)/$(imageTarFile)
      displayName: 'Load Docker image'

    - script: |
        docker tag $(dockerImageName) $(SERVER_IP)/$(dockerImageName):latest
      displayName: 'Tag Docker image'

    - script: |
        echo "$(SSH_PRIVATE_KEY)" > $(sshKeyFile)
        chmod 600 $(sshKeyFile)
        scp -i $(sshKeyFile) $(Pipeline.Workspace)/$(imageTarFile) $(SSH_USER)@$(SERVER_IP):$(serverPath)
      env:
        SSH_PRIVATE_KEY: $(SSH_PRIVATE_KEY)
      displayName: 'Push Docker image to server'

    - script: |
        echo "$(SSH_PRIVATE_KEY)" > $(sshKeyFile)
        chmod 600 $(sshKeyFile)
        ssh -i $(sshKeyFile) $(SSH_USER)@$(SERVER_IP) '
          sudo systemctl start docker || true
          if [ "$(docker ps -q -f name=my-react-container)" ]; then
            docker stop my-react-container
            docker rm my-react-container
          fi
          if [ "$(docker images -q my-react-app)" ]; then
            docker rmi my-react-app || true
          fi
          docker load -i $(serverPath)
          docker run -d --name my-react-container -p 3001:80 my-react-app || { echo "Failed to run container"; exit 1; }
          docker logs my-react-container
        '
      env:
        SSH_PRIVATE_KEY: $(SSH_PRIVATE_KEY)
      displayName: 'Deploy to server'
