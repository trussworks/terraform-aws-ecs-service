package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/stretchr/testify/require"
)

// Retrieve tasks associated with a cluster
func GetTasks(t *testing.T, region string, clusterName string) *ecs.ListTasksOutput {
	var returnTaskList *ecs.ListTasksOutput
	ecsClient, err := aws.NewEcsClientE(t, region)
	require.Nil(t, err, "Error creating ECS client")

	params := &ecs.ListTasksInput{
		Cluster: awssdk.String(clusterName),
	}

	// Need to spin and wait 30s to allow time for resources to get up
	maxRetries := 3
	retryDuration, _ := time.ParseDuration("30s")
	_, err = retry.DoWithRetryE(t, "Get tasks", maxRetries, retryDuration,
		func() (string, error) {
			tasks, _ := ecsClient.ListTasks(params)

			if len(tasks.TaskArns) == 0 {
				return "Did not retrieve tasks", fmt.Errorf("We returned empty tasks %v", tasks.TaskArns)
			}
			returnTaskList = tasks
			return "Retrieved tasks", nil
		},
	)
	require.Nil(t, err, err)

	return returnTaskList
}

// Retrieve ENI from task ARNs and cluster
func GetEni(t *testing.T, region string, cluster string, taskArns []*string) *string {
	var eniDetail *string
	ecsClient, err := aws.NewEcsClientE(t, region)
	require.Nil(t, err, err)

	params := &ecs.DescribeTasksInput{
		Cluster: awssdk.String(cluster),
		Tasks:   taskArns,
	}

	// Retry 3 times at 30s each
	maxRetries := 3
	retryDuration, _ := time.ParseDuration("30s")
	_, err = retry.DoWithRetryE(t, "Get public elastic network interface", maxRetries, retryDuration,
		func() (string, error) {
			returnedTasks, _ := ecsClient.DescribeTasks(params)
			errMessage := "failed to look up public elastic network interface"
			if len(returnedTasks.Tasks) == 0 {
				return errMessage, fmt.Errorf("returned empty tasks %v", returnedTasks.Tasks)
			} else if len(returnedTasks.Tasks[0].Attachments) == 0 {
				return errMessage, fmt.Errorf("returned empty task attachements %v", returnedTasks.Tasks[0].Attachments)
			} else if len(returnedTasks.Tasks[0].Attachments[0].Details) == 1 {
				return errMessage, fmt.Errorf("returned task without public elastic network interface %v", returnedTasks.Tasks[0].Attachments)
			} else {
				eniDetail = returnedTasks.Tasks[0].Attachments[0].Details[1].Value
				return "restrieved public elastice network interface", nil
			}
		},
	)
	require.Nil(t, err, err)

	return eniDetail
}

// Retrieve Public IP from ENI
func GetPublicIP(t *testing.T, region string, enis []string) *string {
	ec2Client := aws.NewEc2Client(t, region)

	params := &ec2.DescribeNetworkInterfacesInput{
		NetworkInterfaceIds: awssdk.StringSlice(enis),
	}
	eniDetail, err := ec2Client.DescribeNetworkInterfaces(params)
	require.Nil(t, err, err)

	publicIP := eniDetail.NetworkInterfaces[0].Association.PublicIp
	return publicIP
}

func EcsExecCommand(t *testing.T, region string, cluster string, command string) error {
	ecsClient, err := aws.NewEcsClientE(t, region)
	if err != nil {
		return err
	}

	tasksOutput := GetTasks(t, region, cluster)
	taskSplit := strings.Split(*tasksOutput.TaskArns[0], "/")
	task := taskSplit[len(taskSplit)-1]

	params := &ecs.ExecuteCommandInput{
		Cluster:     awssdk.String(cluster),
		Command:     awssdk.String(command),
		Task:        awssdk.String(task),
		Interactive: awssdk.Bool(true),
	}

	maxRetries := 3
	retryDuration, _ := time.ParseDuration("30s")
	_, err = retry.DoWithRetryE(t, fmt.Sprintf("Execute ECS command with params %v", params), maxRetries, retryDuration, func() (string, error) {
		req, _ := ecsClient.ExecuteCommandRequest(params)
		err = req.Send()
		if err != nil {
			return "failed to execute command", err
		}
		return fmt.Sprintf("Executed command %s", command), nil
	},
	)
	return err
}
