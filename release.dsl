/*
DSL used to create release pipeline with controls and checks enforced

usage: ectool evalDsl --dslFile release.dsl --parametersFile manifest/releases/sodApp1Release.json --overwrite 1

example json file as below:
{
  "projectName": "SoD-Holy",
  "releaseName": "sod-dev-release",
  "deployApplicationName": "SoDApp",    # the application name you need to deploy in each stage
  "teamAdminGroupName":"SoD-Holy-admin-group", # the team admin group name here, acls will be setup in the release/pipeline stages
  "developersGroupName":"SoD-Holy-developers-group", # the developers group name here, acls will be setup in the release/pipeline stages
  "operationsGroupName":"SoD-Holy-operations-group", # the operations group name here, acls will be setup in the release/pipeline stages
  "approversGroupNames":["SoD-Holy-approvers-group"], # the approvers group names here, acls will be setup int he release/pipeline stages, you can put multiple group name here. please be aware that there is [] 
  "releasePlannedStartDate":"2021-12-25", #the planned release start date with format YYYY-MM-DD
  "releasePlannedEndDate":"2022-12-25", #the planned release end date with format YYYY-MM-DD

  #stages definition, in the [] we can define as many stages as we want
  "stages" : [
    {
      "stageName": "Dev",  #name of the stage
      "colorCode": "red", #color of the stage, can use color code as well
      "isProduction": "false",  #is this a production stage, means do we need to deploy to a production environment, differnet controls/approver checks will be applied
      "deployProcessName": "Deploy", #the application deploy process name to do the deployment
      "environmentName": "SoDApp-Dev" #target environment to deploy the application to.
    },
    {
      "stageName": "QA",
      "colorCode": "yellow",
      "isProduction": "false",
      "deployProcessName": "Deploy",
      "environmentName": "SoDApp-QA"
    },
    {
      "stageName": "Prod",
      "colorCode": "green",
      "isProduction": "true",
      "deployProcessName": "Deploy",
      "environmentName": "SoDApp-Prod"
    }
  ]
}


*/

def myReleaseName = args.releaseName
def myProjectName = args.projectName
def myPipelineName =  'pipeline_' + myReleaseName
def myApplicationName = args.deployApplicationName
def teamAdminGroupName = args.teamAdminGroupName
def developersGroupName = args.developersGroupName
def operationsGroupName = args.operationsGroupName
def approversGroupNames = args.approversGroupNames

def myStages = args.stages


//creating release
release myReleaseName, {
  //setting release planned start/end date
  plannedEndDate = args.releasePlannedEndDate
  plannedStartDate = args.releasePlannedStartDate
  projectName = myProjectName

  //setting up release level acl
  acl {
    inheriting = '1' //inherit from the parent project

    //team admin access, allow execute but deny modify
    aclEntry 'group', principalName: teamAdminGroupName, {
      changePermissionsPrivilege = 'inherit'
      executePrivilege = 'allow'
      modifyPrivilege = 'deny'
      readPrivilege = 'inherit'
    }

    //developer access, allow execute but deny modify
    aclEntry 'group', principalName: developersGroupName, {
      changePermissionsPrivilege = 'inherit'
      executePrivilege = 'allow'
      modifyPrivilege = 'deny'
      readPrivilege = 'inherit'
    }

    //operations access, allow execute
    aclEntry 'group', principalName: operationsGroupName, {
      changePermissionsPrivilege = 'inherit'
      executePrivilege = 'allow'
      modifyPrivilege = 'inherit'
      readPrivilege = 'inherit'
    }
  }

  //creating the pipeline for the release
  pipeline myPipelineName, {
    projectName = myProjectName
    releaseName = myReleaseName

    formalParameter 'ec_stagesToRun', {
      expansionDeferred = '1'
    }

    //populating the stages of the pipeline
    myStages.each { stageItem ->
        stage stageItem.stageName, {
          colorCode = stageItem.colorCode
          pipelineName = myPipelineName
          projectName = myProjectName

          //pre gate rules
          gate 'PRE', {
            projectName = myProjectName

            //only check the service account if it's a production environment
            if(stageItem.isProduction == 'true'){
              task 'serviceAccountCheck', {
                gateType = 'PRE'
                actualParameter = [
                  'repoName': 'Macquarie AD Generics',
                  'userName': '$[/myPipelineRuntime/launchedByUser]',
                ]
                subpluginKey = 'MGL-Utils'
                subprocedure = 'Service Account Check'
                taskType = 'PLUGIN'
              }
            }

            //don't need to do resource type check if it's not a production environment
            if(stageItem.isProduction != 'true'){
              task 'resourceCheck', {
                gateType = 'PRE'
                actualParameter = [
                  'config': '/projects/Developer Tools/pluginConfigurations/CMDB Integration',
                  'environmentName': stageItem.environmentName,
                  'isProduction': stageItem.isProduction,
                  'projectName': myProjectName,
                ]
                subpluginKey = 'MGL-Utils'
                subprocedure = 'Resource Type Check'
                taskType = 'PLUGIN'
              }
            }

            //manual approval for production environment
            if(stageItem.isProduction == 'true'){
              //manual approval task
              task 'deployment to production', {
                gateType = 'PRE'
                notificationEnabled = '1'
                notificationTemplate = 'ec_default_gate_task_notification_template'
                projectName = myProjectName
                subproject = myProjectName
                taskType = 'APPROVAL'
                approver = approversGroupNames
              }

              //make sure that the approver is not a service account
              task 'serviceAccountCheckForApprover', {
                gateType = 'PRE'
                actualParameter = [
                  'repoName': 'Macquarie AD Generics',
                  'userName': '$[/myGateRuntime/tasks[\'deployment to production\']/lastModifiedBy]',
                ]
                subpluginKey = 'MGL-Utils'
                subprocedure = 'Service Account Check'
                taskType = 'PLUGIN'
              }

              //make sure that the approver is not the same with the one who run this pipeline
              task 'approverCheck', {
                gateCondition = '''
                $[/javascript
                  if( myGateRuntime.tasks[\'deployment to production\'].lastModifiedBy != myPipelineRuntime.launchedByUser) {
                    true;
                  }
                  else {
                    setProperty("/myTaskRuntime/evidence", "Approver and Initiator can not be the same")
                    false;
                  }
                ]'''.stripIndent()
                gateType = 'PRE'
                projectName = myProjectName
                subproject = myProjectName
                taskType = 'CONDITIONAL'
              }
            }
          }

          //deployer task
          task 'Deploy', {
            deployerRunType = 'serial'
            projectName = myProjectName
            subproject = myProjectName
            taskType = 'DEPLOYER'
          }

          //hide the production stage from developers group
          if(stageItem.isProduction == 'true'){
            acl {
              inheriting = '1'

              aclEntry 'group', principalName: developersGroupName, {
                changePermissionsPrivilege = 'inherit'
                executePrivilege = 'inherit'
                modifyPrivilege = 'inherit'
                readPrivilege = 'deny'
              }
            }
          }
        }

    }
  }

}

//update the deployerconfiguration for the release
transaction {
  release myReleaseName, {
    projectName = myProjectName
    deployerApplication myApplicationName, {
      orderIndex = '1'
      processName = myStages.first().deployProcessName
      smartDeploy = '0'

      myStages.each { stageItem ->
        deployerConfiguration "deployerconfig-" + stageItem.stageName + "-" + stageItem.environmentName, {
          deployerTaskName = 'Deploy'
          environmentName = stageItem.environmentName
          projectName = myProjectName
          stageName = stageItem.stageName
          processName = stageItem.deployProcessName
        }
      }
    }
  }
}