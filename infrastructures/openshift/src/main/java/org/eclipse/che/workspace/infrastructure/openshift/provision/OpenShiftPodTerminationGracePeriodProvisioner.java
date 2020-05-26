/*
 * Copyright (c) 2012-2018 Red Hat, Inc.
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *   Red Hat, Inc. - initial API and implementation
 */
package org.eclipse.che.workspace.infrastructure.openshift.provision;

import static org.eclipse.che.api.workspace.shared.Constants.ASYNC_PERSIST_ATTRIBUTE;
import static org.eclipse.che.workspace.infrastructure.kubernetes.namespace.pvc.EphemeralWorkspaceUtility.isEphemeral;

import io.fabric8.kubernetes.api.model.PodSpec;
import javax.inject.Inject;
import javax.inject.Named;
import org.eclipse.che.api.core.model.workspace.runtime.RuntimeIdentity;
import org.eclipse.che.commons.annotation.Traced;
import org.eclipse.che.commons.tracing.TracingTags;
import org.eclipse.che.workspace.infrastructure.kubernetes.environment.KubernetesEnvironment;
import org.eclipse.che.workspace.infrastructure.kubernetes.environment.KubernetesEnvironment.PodData;
import org.eclipse.che.workspace.infrastructure.kubernetes.provision.PodTerminationGracePeriodProvisioner;

public class OpenShiftPodTerminationGracePeriodProvisioner
    extends PodTerminationGracePeriodProvisioner {

  private final long graceTerminationPeriodAsyncPvc = 60;
  private final long graceTerminationPeriodSec;

  @Inject
  public OpenShiftPodTerminationGracePeriodProvisioner(
      @Named("che.infra.kubernetes.pod.termination_grace_period_sec")
          long graceTerminationPeriodSec) {
    super(graceTerminationPeriodSec);
    this.graceTerminationPeriodSec = graceTerminationPeriodSec;
  }

  @Override
  @Traced
  public void provision(KubernetesEnvironment k8sEnv, RuntimeIdentity identity) {

    TracingTags.WORKSPACE_ID.set(identity::getWorkspaceId);

    for (PodData pod : k8sEnv.getPodsData().values()) {
      if (!isTerminationGracePeriodSet(pod.getSpec())) {
        pod.getSpec().setTerminationGracePeriodSeconds(getGraceTerminationPeriodSec(k8sEnv));
      }
    }
  }

  /**
   * Returns true if 'terminationGracePeriodSeconds' have been explicitly set in Kubernetes /
   * OpenShift recipe, false otherwise
   */
  private boolean isTerminationGracePeriodSet(final PodSpec podSpec) {
    return podSpec.getTerminationGracePeriodSeconds() != null;
  }

  private long getGraceTerminationPeriodSec(KubernetesEnvironment k8sEnv) {
    if (isEphemeral(k8sEnv.getAttributes())
        && "true".equals(k8sEnv.getAttributes().get(ASYNC_PERSIST_ATTRIBUTE))) {
      return graceTerminationPeriodAsyncPvc;
    }
    return graceTerminationPeriodSec;
  }
}
