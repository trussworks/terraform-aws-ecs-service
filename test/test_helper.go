package test

import (
	"fmt"
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
	taskList, err := GetTasksE(t, region, clusterName)
	require.NoError(t, err)
	return taskList
}

func GetTasksE(t *testing.T, region string, clusterName string) (*ecs.ListTasksOutput, error) {
	var returnTaskList *ecs.ListTasksOutput
	ecsClient, err := aws.NewEcsClientE(t, region)
	if err != nil {
		return returnTaskList, err
	}

	params := &ecs.ListTasksInput{
		Cluster: awssdk.String(clusterName),
	}

	// Need to spin and wait to allow time for resources to get up
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
	if err != nil {
		return returnTaskList, err
	}

	return returnTaskList, nil
}

// Retrieve ENI from task ARNs and cluster
func GetEni(t *testing.T, region string, cluster string, taskArns []*string) *string {
	eni, err := GetEniE(t, region, cluster, taskArns)
	require.NoError(t, err)
	return eni
}

func GetEniE(t *testing.T, region string, cluster string, taskArns []*string) (*string, error) {
	var eniDetail *string
	ecsClient, err := aws.NewEcsClientE(t, region)
	if err != nil {
		return nil, err
	}

	params := &ecs.DescribeTasksInput{
		Cluster: awssdk.String(cluster),
		Tasks:   taskArns,
	}

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
	if err != nil {
		return eniDetail, err
	}
	return eniDetail, nil
}

// Retrieve Public IP from ENI
func GetPublicIP(t *testing.T, region string, enis []string) *string {
	publicIP, err := GetPublicIPE(t, region, enis)
	require.NoError(t, err)
	return publicIP
}

func GetPublicIPE(t *testing.T, region string, enis []string) (*string, error) {
	ec2Client := aws.NewEc2Client(t, region)

	params := &ec2.DescribeNetworkInterfacesInput{
		NetworkInterfaceIds: awssdk.StringSlice(enis),
	}
	eniDetail, err := ec2Client.DescribeNetworkInterfaces(params)
	if err != nil {
		return nil, err
	}

	publicIP := eniDetail.NetworkInterfaces[0].Association.PublicIp
	return publicIP, nil
}
