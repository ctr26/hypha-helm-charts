.PHONY: minikube.setup
CT_CONFIG = ct.yaml


build: lint helm.package

cluster: minikube.setup
	@echo "Cluster setup complete"
minikube.setup:
	minikube config set memory 16384
	minikube config set cpus 4
	minikube config set disk-size 32GB
	minikube start --addons=gpu,ingress,nvidia-driver-installer,nvidia-gpu-device-plugin 

helm.package:
	helm package charts/hypha --dependency-update --destination helm-chart
	helm package charts/tritoninferenceserver-hypha --dependency-update --destination helm-chart
# VERSION=$(shell grep -Eo '[0-9]\.[0-9]\.[0-9]+' helm-chart/hypha/Chart.yaml | head -1)

VERSION=$(shell grep -Po "(?<=version: )([0-9]|\.)*(?=\s|$$)" charts/hypha/Chart.yaml | head -1)

get.version:
	echo $(VERSION)

tag.release:
	version=${VERSION}
	echo "Tagging release ${VERSION}"
	git tag -a "v${VERSION}" -m "v${VERSION}" -f
	git push origin

install.helm:
	helm upgrade hypha charts/hypha --install --timeout 20m

install.ct:
	ct install --config ct.yaml 

install: install.ct
test:
	helm test hypha

install.and.test: install test

uninstall:
	helm uninstall hypha

upload.test.models:
	kubectl create configmap model-repository --from-file=tests/model_repository

lint:
	ct lint --config $(CT_CONFIG)

full.test: lint install.and.test

cluster.test:

clean: 
	minikube delete

reset: clean cluster

gha:
	act --container-architecture linux/arm64