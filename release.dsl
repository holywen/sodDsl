def myReleaseName = args.releaseName
def myProjectName = args.projectName
def myPipelineName =  'pipeline_' + myReleaseName
def myApplicationName = args.deployApplicationName
def myStages = args.stages

release myReleaseName, {
  plannedEndDate = '2022-01-25'
  plannedStartDate = '2022-01-11'
  projectName = myProjectName

  pipeline myPipelineName, {
    projectName = myProjectName
    releaseName = myReleaseName

    formalParameter 'ec_stagesToRun', {
      expansionDeferred = '1'
    }

    myStages.each { stageItem ->
        stage stageItem.stageName, {
          colorCode = stageItem.colorCode
          pipelineName = myPipelineName
          projectName = myProjectName

          gate 'PRE', {
            projectName = myProjectName

            if(stageItem.isProduction == 'true'){
              task 'serviceAccountCheck', {
                gateType = 'PRE'
                actualParameter = [
                  'repoName': 'Macquarie Generic',
                  'userName': '$[/myPipelineRuntime/launchedByUser]',
                ]
                subpluginKey = 'MBL-Utils'
                subprocedure = 'Service Account Check'
                taskType = 'PLUGIN'
              }
            }

            task 'resourceCheck', {
              gateType = 'PRE'
              actualParameter = [
                'environmentName': stageItem.environmentName,
                'isProduction': stageItem.isProduction,
                'projectName': myProjectName,
              ]
              subpluginKey = 'MBL-Utils'
              subprocedure = 'Resource Type Check'
              taskType = 'PLUGIN'
            }

            if(stageItem.isProduction == 'true'){
              task 'deployment to production', {
                gateType = 'PRE'
                notificationEnabled = '1'
                notificationTemplate = 'ec_default_gate_task_notification_template'
                projectName = myProjectName
                subproject = myProjectName
                taskType = 'APPROVAL'
                approver = stageItem.approverGroups
              }

              task 'serviceAccountCheckForApprover', {
                gateType = 'PRE'
                actualParameter = [
                  'repoName': 'Macquarie Generic',
                  'userName': '$[/myGateRuntime/tasks[\'deployment to production\']/lastModifiedBy]',
                ]
                subpluginKey = 'MBL-Utils'
                subprocedure = 'Service Account Check'
                taskType = 'PLUGIN'
              }

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

          task 'Deploy', {
            deployerRunType = 'serial'
            projectName = myProjectName
            subproject = myProjectName
            taskType = 'DEPLOYER'
          }
        }

    }
  }

}

transaction {
  release myReleaseName, {
    projectName = myProjectName
    deployerApplication myApplicationName, {
      orderIndex = '1'
      processName = 'Deploy'
      smartDeploy = '0'

      myStages.each { stageItem ->
        deployerConfiguration "deployerconfig-" + stageItem.stageName + "-" + stageItem.environmentName, {
          deployerTaskName = 'Deploy'
          environmentName = stageItem.environmentName
          projectName = myProjectName
          stageName = stageItem.stageName
        }
      }
    }
  }
}