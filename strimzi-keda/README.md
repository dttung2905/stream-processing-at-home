## Test code for KEDA issue https://github.com/kedacore/keda/issues/5102

- Install helm kafka and kafka helm release
```bash
terraform apply --target=helm_release.keda
terraform apply --target=kubectl_manifest.kafka_cluster
```
- Create the mixed-case topic `kafkaTopic`
```bash
terraform apply --target=kubectl_manifest.kafka-topic-my-topic
```
  The topic should exist
```bash
[kafka@test-cluster-kafka-0 kafka]$ bin/kafka-topics.sh --list --bootstrap-server test-cluster-kafka-bootstrap.default.svc:9092
__consumer_offsets
__strimzi-topic-operator-kstreams-topic-store-changelog
__strimzi_store_topic
myTopic
```
- Create the consumer and follow up by creating the KEDA scaledObject
```bash
terraform apply --target=kubectl_manifest.kafka-consumer-app
terraform apply --target=kubectl_manifest.kafka_scaled_object
```
- Now you will see the consumer pod being scaled out to 5 replicas. Describing HPA will give the following information
```
❯ k describe hpa keda-hpa-kafka-scaledobject
Name:                                         keda-hpa-kafka-scaledobject
Namespace:                                    default
Labels:                                       app.kubernetes.io/managed-by=keda-operator
                                              app.kubernetes.io/name=keda-hpa-kafka-scaledobject
                                              app.kubernetes.io/part-of=kafka-scaledobject
                                              app.kubernetes.io/version=2.12.0
                                              scaledobject.keda.sh/name=kafka-scaledobject
Annotations:                                  <none>
CreationTimestamp:                            Sat, 06 Jan 2024 10:34:41 +0000
Reference:                                    Deployment/kafka-consumer
Metrics:                                      ( current / target )
  "s0-kafka-myTopic" (target average value):  0 / 5
Min replicas:                                 1
Max replicas:                                 100
Deployment pods:                              5 current / 5 desired
Conditions:
  Type            Status  Reason               Message
  ----            ------  ------               -------
  AbleToScale     True    ScaleDownStabilized  recent recommendations were higher than current one, applying the highest recent recommendation
  ScalingActive   True    ValidMetricFound     the HPA was able to successfully calculate a replica count from external metric s0-kafka-myTopic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},})
  ScalingLimited  False   DesiredWithinRange   the desired count is within the acceptable range
Events:
  Type    Reason             Age    From                       Message
  ----    ------             ----   ----                       -------
  Normal  SuccessfulRescale  9m     horizontal-pod-autoscaler  New size: 4; reason: external metric s0-kafka-myTopic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},}) above target
  Normal  SuccessfulRescale  8m45s  horizontal-pod-autoscaler  New size: 5; reason: external metric s0-kafka-myTopic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},}) above target
```
- Wait for a while until the consumer lag is 0. The consumer will be scaled down from 5 to 1 pods and finally 0 pods
```
❯ k exec -it test-cluster-kafka-0 -- bash
Defaulted container "kafka" out of: kafka, kafka-init (init)
[kafka@test-cluster-kafka-0 kafka]$ bin/kafka-consumer-groups.sh --bootstrap-server test-cluster-kafka-bootstrap.default.svc:9092 --describe --group my-kafka-consumer

GROUP             TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                                       HOST            CLIENT-ID
my-kafka-consumer myTopic         4          1204485         1204485         0               consumer-my-kafka-consumer-1-c8e6f2a0-6cc4-41bc-a7ce-3c738f75e3c6 /10.244.0.18    consumer-my-kafka-consumer-1
my-kafka-consumer myTopic         2          1175266         1175266         0               consumer-my-kafka-consumer-1-54ac10db-4924-494b-be1b-af75bf883867 /10.244.0.21    consumer-my-kafka-consumer-1
my-kafka-consumer myTopic         0          1191455         1191455         0               consumer-my-kafka-consumer-1-07279d90-3dbf-4885-9fa0-d684edd056f3 /10.244.0.12    consumer-my-kafka-consumer-1
my-kafka-consumer myTopic         1          1201317         1201317         0               consumer-my-kafka-consumer-1-2e09d0c7-0425-4db5-881a-4c26c926a719 /10.244.0.22    consumer-my-kafka-consumer-1
my-kafka-consumer myTopic         3          1227477         1227477         0               consumer-my-kafka-consumer-1-a88d9d8c-cb5e-4a9a-8a63-1adb8252a4ed /10.244.0.20    consumer-my-kafka-consumer-1
```

```
❯ k describe hpa keda-hpa-kafka-scaledobject
Name:                                         keda-hpa-kafka-scaledobject
Namespace:                                    default
Labels:                                       app.kubernetes.io/managed-by=keda-operator
                                              app.kubernetes.io/name=keda-hpa-kafka-scaledobject
                                              app.kubernetes.io/part-of=kafka-scaledobject
                                              app.kubernetes.io/version=2.12.0
                                              scaledobject.keda.sh/name=kafka-scaledobject
Annotations:                                  <none>
CreationTimestamp:                            Sat, 06 Jan 2024 10:34:41 +0000
Reference:                                    Deployment/kafka-consumer
Metrics:                                      ( current / target )
  "s0-kafka-myTopic" (target average value):  <unknown> / 5
Min replicas:                                 1
Max replicas:                                 100
Deployment pods:                              0 current / 0 desired
Conditions:
  Type            Status  Reason             Message
  ----            ------  ------             -------
  AbleToScale     True    SucceededGetScale  the HPA controller was able to get the target's current scale
  ScalingActive   False   ScalingDisabled    scaling is disabled since the replica count of the target is zero
  ScalingLimited  True    TooFewReplicas     the desired replica count is less than the minimum replica count
Events:
  Type    Reason             Age    From                       Message
  ----    ------             ----   ----                       -------
  Normal  SuccessfulRescale  9m59s  horizontal-pod-autoscaler  New size: 4; reason: external metric s0-kafka-myTopic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},}) above target
  Normal  SuccessfulRescale  9m44s  horizontal-pod-autoscaler  New size: 5; reason: external metric s0-kafka-myTopic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},}) above target
  Normal  SuccessfulRescale  28s    horizontal-pod-autoscaler  New size: 1; reason: All metrics below target

```
- We can get the metrics straight from metrics server too
```
 kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/s0-kafka-myTopic?labelSelector=scaledobject.keda.sh%2Fname%3Dkafka-scaledobject" | jq
{
  "kind": "ExternalMetricValueList",
  "apiVersion": "external.metrics.k8s.io/v1beta1",
  "metadata": {},
  "items": [
    {
      "metricName": "s0-kafka-myTopic",
      "metricLabels": null,
      "timestamp": "2024-01-06T10:47:33Z",
      "value": "0"
    }
  ]
}
```
