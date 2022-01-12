def myReleaseName = args.releaseName
def myProjectName = args.projectName
def myPipelineName =  'pipeline_' + myReleaseName

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

    stage 'Dev', {
      colorCode = '#289ce1'
      pipelineName = myPipelineName
      projectName = myProjectName

      gate 'PRE', {
        projectName = myProjectName

        task 'resource-check', {
          gateType = 'PRE'
          projectName = myProjectName
          subprocedure = 'resourceCheck'
          subproject = myProjectName
          taskType = 'PROCEDURE'
        }

        task 'approval', {
          gateType = 'PRE'
          notificationEnabled = '1'
          notificationTemplate = 'ec_default_gate_task_notification_template'
          projectName = myProjectName
          subproject = myProjectName
          taskType = 'APPROVAL'
          approver = [
            'Everyone',
          ]
        }
      }

      gate 'POST', {
        projectName = myProjectName
      }

      task 'Deploy', {
        deployerRunType = 'serial'
        projectName = myProjectName
        subproject = myProjectName
        taskType = 'DEPLOYER'
      }
    }

    stage 'QA', {
      colorCode = '#289ce1'
      pipelineName = myPipelineName
      projectName = myProjectName

      gate 'PRE', {
        projectName = myProjectName

        task 'resource-check', {
          gateType = 'PRE'
          projectName = myProjectName
          subprocedure = 'resourceCheck'
          subproject = myProjectName
          taskType = 'PROCEDURE'
        }

        task 'approval', {
          gateType = 'PRE'
          notificationEnabled = '1'
          notificationTemplate = 'ec_default_gate_task_notification_template'
          projectName = myProjectName
          subproject = myProjectName
          taskType = 'APPROVAL'
          approver = [
            'Everyone',
          ]
        }
      }

      gate 'POST', {
        projectName = myProjectName
      }

      task 'Deploy', {
        deployerRunType = 'serial'
        projectName = myProjectName
        subproject = myProjectName
        taskType = 'DEPLOYER'
      }
    }

    stage 'Prod', {
      colorCode = '#289ce1'
      pipelineName = myPipelineName
      projectName = myProjectName

      gate 'PRE', {
        projectName = myProjectName

        task 'launcher-check', {
          gateType = 'PRE'
          projectName = myProjectName
          subprocedure = 'launcherCheck'
          subproject = myProjectName
          taskType = 'PROCEDURE'
        }

        task 'resource-check', {
          gateType = 'PRE'
          projectName = myProjectName
          subprocedure = 'resourceCheck'
          subproject = myProjectName
          taskType = 'PROCEDURE'
        }

        task 'deployment to production', {
          gateType = 'PRE'
          notificationEnabled = '1'
          notificationTemplate = 'ec_default_gate_task_notification_template'
          projectName = myProjectName
          subproject = myProjectName
          taskType = 'APPROVAL'
          approver = [
            'Everyone',
          ]
        }

        task 'approverCheck', {
          gateCondition = '''$[/javascript 
 if( myGateRuntime.tasks[\'deployment to production\'].lastModifiedBy != myPipelineRuntime.launchedByUser) {
   true;
}
else {
  setProperty("/myTaskRuntime/evidence", "Approver and Initiator can not be the same")
  false;
}
]'''
          gateType = 'PRE'
          projectName = myProjectName
          subproject = myProjectName
          taskType = 'CONDITIONAL'
        }
      }

      gate 'POST', {
        projectName = myProjectName
      }

      task 'Deploy', {
        deployerRunType = 'serial'
        projectName = myProjectName
        subproject = myProjectName
        taskType = 'DEPLOYER'
      }
    }
  }

  deployerApplication 'SoDApp', {
    orderIndex = '1'
    processName = 'Deploy'
    smartDeploy = '0'

    deployerConfiguration '3830323d-7360-11ec-95cd-02426ce5a855', {
      deployerTaskName = 'Deploy'
      environmentName = 'SoDApp-Dev'
      projectName = myProjectName
      stageName = 'Dev'
    }

    deployerConfiguration 'a50670db-7360-11ec-9ad4-02426ce5a855', {
      deployerTaskName = 'Deploy'
      environmentName = 'SoDApp-QA'
      projectName = myProjectName
      stageName = 'QA'
    }

    deployerConfiguration 'a5145330-7360-11ec-b968-02426ce5a855', {
      deployerTaskName = 'Deploy'
      environmentName = 'SoDApp-Prod'
      projectName = myProjectName
      stageName = 'Prod'
    }
  }
}
