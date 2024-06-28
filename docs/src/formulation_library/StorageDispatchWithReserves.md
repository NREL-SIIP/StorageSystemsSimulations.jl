# `StorageDispatchWithReserves` Formulation

```@docs
StorageDispatchWithReserves
```

## Attributes

  - `"reservation"`: Forces the storage to operate exclusively on charge or discharge mode through the entire operation interval. We recommend setting this to false for models with relatively longer time resolutions (e.g., 1-Hr) since the storage can take simultaneous charge or discharge positions on average over the period.
  - `"cycling_limits"`: This limits the storage's energy cycling. A single charging (discharging) cycle is fully charging (discharging) the storage once. The calculation uses the total energy charge/discharge and the number of cycles. Currently, the formulation only supports a fixed value per operation period. Additional variables for [`StorageChargeCyclingSlackVariable`](@ref) and [`StorageDischargeCyclingSlackVariable`](@ref) are included in the model if `use_slacks` is set to `true`.
  - `"energy_target"`: Set a target at the end of the model horizon for the storage's state of charge. Currently, the formulation only supports a fixed value per operation period. Additional variables for [`StorageEnergyShortageVariable`](@ref) and [`StorageEnergySurplusVariable`](@ref) are included in the model if `use_slacks` is set to `true`.

!!! warning
    
    Combining cycle limits and energy target attributes is not recommended. Both
    attributes impose constraints on energy. There is no guarantee that the constraints can be satisfied simultaneously.

  - `"complete_coverage"`: This attribute implements constraints that require the battery to cover the sum of all the ancillary services it participates in simultaneously. It is equivalent to holding energy in case all the services get deployed simultaneously. This constraint is added to the constraints that cover each service independently and corresponds to a more conservative operation regime.
  - `"regularization"`: This attribute smooths the charge/discharge profiles to avoid bang-bang solutions via a penalty on the absolute value of the intra-temporal variations of the charge and discharge power. Solving for optimal storage dispatch can stall in models with large amounts of curtailment or long periods with negative or zero prices due to numerical degeneracy. The regularization term is scaled by the storage device's power limits to normalize the term and avoid additional penalties to larger storage units.

!!! danger
    
    Setting the energy target attribute in combination with [`EnergyTargetFeedforward`](@ref) or [`EnergyLimitFeedforward`](@ref) is not permitted and StorageSystemsSimulations will throw an exception.

## Mathematical Model

### Sets

```math
\begin{align*}
    &\mathcal{P}^{\text{as}_\text{up}} & \text{Up Ancillary Service Products Set}\\
    &\mathcal{P}^{\text{as}_\text{dn}} & \text{Down Ancillary Service Products Set}\\
    &\mathcal{P}^{\text{as}} := \bigcup\left\{ \mathcal{P}^{\text{as}_\text{up}}, \mathcal{P}^{\text{as}_\text{dn}}\right\} & \text{Ancillary Service Products Set}\\
    &\mathcal{T} := \{1,\dots,T\} & \text{Time steps} \\
\end{align*}
```

### Parameters

#### Operational Parameters

```math
\begin{align*}
    &P^{max,ch}_{st} &\text{Max Charge Power Storage [MW]}\\
    &P^{max,ds}_{st} &\text{Max Discharge Power Storage [MW]}\\
    &\eta^{ch}_{st} &\text{Charge Efficiency Storage [\%/hr]}\\
    &\eta^{ds}_{st} &\text{Discharge Efficiency Storage [\%/hr]}\\
    &R^{*}_{p, t} &\text{Ancillary Service deployment Forecast at time $t$ for service $p \in \mathcal{P}^{\text{as}}$ [\$/MW]}\\
    &E^{max}_{st} &\text{Max Energy Storage Capacity [MWh]}\\
    &E^{st}_{0} &\text{Storage initial energy [MWh]}\\
    &E^{st}_{T} &\text{Storage Energy Target at the end of the horizon, i.e., time-step $T$ [MWh]}\\
    &\Delta t  &\text{Timestep length}\\
    &C_{st} & \text{Maximum number of cycles over the horizon.} \\
    && \text{For DA the value is fixed to 3 and in RT the value depends on the DA allocation of cycles} \\
    &N_{p} & \text{Number of periods of compliance to supply an AS.}\\
    && \text{For example Spinning reserve has 12 for 1 hour of compliance when $\Delta_t$ is 5-minutes.}
\end{align*}
```

#### Cost Parameters

```math
\begin{align*}
    &\text{VOM} &\text{Storage Variable Operation and Maintenance Cost [\%/MWh]}\\
    &\rho^{e+} &\text{Storage Surplus penalty at end of target cost [\$/MWh]. Used when \texttt{use\_slacks = true}}\\
    &\rho^{e-} &\text{Storage Shortage penalty at end of target cost [\$/MWh]. Used when \texttt{use\_slacks = true}}\\
    &\rho^{c} &\text{Storage Cycling Penalty [\$/MWh]. Used when \texttt{use\_slacks = true}}\\
    &\rho^{z} &\text{Regularization Terms Penalty. Used when \texttt{"regularization" => true}}\\
\end{align*}
```

### Variables

```math
\begin{align*}
    &p^{st, ch}_{t}  & \in [0, P^{max,ch}_{st}] &\quad\text{Expected Storage charging power}\\
    &p^{st, ds}_{t}  & \in [0, P^{max,ds}_{st}] &\quad\text{Expected Storage discharging power}\\
    &e^{st}_{t}  & \in [0, E^{max}_{st}] &\quad \text{Expected Storage Energy}\\
    &\text{ss}^{st}_{t}  & \in \{ 0, 1 \} &\quad \text{Charge/Discharge status Storage. Used when \texttt{"reservation" => true}}\\
    &sb_{stc,p,t} & \in [0, P^{max,ch}_{st}] & \quad \text{Ancillary service fraction assigned to Storage Charging}\\
    &sb_{std,p,t} & \in [0, P^{max,ds}_{st}] & \quad \text{Ancillary service fraction assigned to Storage Discharging}\\
    &e^{st+}  & \in [0, E^{max}_{st}] &\quad \text{Storage Energy Surplus above target. Used when \texttt{use\_slacks = true}}\\
    &e^{st-}  & \in [0, E^{max}_{st}] &\quad \text{Storage Energy Shortage below target. Used when \texttt{use\_slacks = true}}\\
    &c^{ch-}  & \in [0, T C_{st}] &\quad \text{Charging Cycling Shortage. Used when \texttt{use\_slacks = true}}\\
    &c^{ds-}  & \in [0, T C_{st}] &\quad \text{Discharging Cycling Shortage. Used when \texttt{use\_slacks = true}}\\
    &z^{st, ch}_{t} & \in [0, P^{max,ch}_{st}] &\quad \text{Regularization charge variable. Used when \texttt{"regularization" => true}}\\
    &z^{st, ds}_{t} & \in [0, P^{max,ds}_{st}] &\quad \text{Regularization discharge variable. Used when \texttt{"regularization" => true}}\\
\end{align*}
```

### Model

```math
\begin{aligned}
\min_{\substack{\boldsymbol{p}^{st, ch}, \boldsymbol{p}^{st, ds}, \boldsymbol{e}^{st}, \\ e^{st+}, e^{st-}, c^{ch-} + c^{ds-}}}
& \rho^{e+} e^{st+} + \rho^{e-} e^{st-} + \rho^{c} \left(c^{ch-} + c^{ds-} \right) + \rho^{z} \left(\frac{z^{ch}}{P^{max,ch}_{st}} + \frac{z^{ds}}{P^{max,ds}_{st}} \right)\\
& +\Delta t \sum_{t \in \mathcal{T}} \text{VOM}_{st} \left ( \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t} \right) + \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t}\right) \right) &
\end{aligned}
```

```math
\begin{aligned}
\text{s.t.}  & &\\
&\text{Power Limit Constraints.}&\\
&p^{st, ch}_{t} + \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} sb_{stc,p,t} \leq (1 - \text{ss}^{st}_{t})P^{max,ch}_{st} & \quad \forall t \in \mathcal{T} \\
& p^{st, ch}_{t} - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} sb_{stc,p,t} \geq 0 & \quad \forall t \in \mathcal{T}\\
& p^{st, ds}_{t} + \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} sb_{std,p,t} \leq \text{ss}^{st}_{t}P^{max,ds}_{st} & \forall t \in \mathcal{T}\\
& p^{st, ds}_{t} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} sb_{std,p,t} \geq 0 & \forall t \in \mathcal{T}\\
&\text{Energy Storage Limit Constraints}&\\
&e^{st}_{t} \leq E^{max}_{st} & \forall t \in \mathcal{T}\\
& e^{st}_{t} \geq E^{min}_{st} & \forall t \in \mathcal{T}\\
&\text{Energy Bookkeeping constraints}&\\
& E^{st}_{0} + \Delta t  \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,1} sb_{stc,p,1} + p^{st,ch}_{1}  - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,1} sb_{stc,p,1}\right)\eta^{ch}_{st}&\\
&-\Delta t\left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,1} sb_{std,p,1} + p^{st,ds}_{1} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{std,p,1}\right)\frac{1}{\eta^{ds}_{st}}=e^{st}_{1}\\
&e^{st}_{t-1} + \Delta t  \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t}  - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{stc,p,t}\right)\eta^{ch}_{st}&\\
&-\Delta t\left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{std,p,t}\right)\frac{1}{\eta^{ds}_{st}} =e^{st}_{t} & \forall t \in \mathcal{T} \setminus {1}\\
&\text{End of period energy target constraint. Used when \texttt{"energy\_target" => true}}&\\
&e^{st}_{T} + e^{st+} - e^{st-} = E^{st}_{T}&\\
&\text{Storage Cycling Limits Constraints. Used when \texttt{"cycling\_limits" => true}}&\\
& \sum_{t \in \mathcal{T}} \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t}\right)\frac{1}{\eta^{ds}_{st}} \Delta t - c^{ds-} \leq C_{st} E^{max}_{st} &\\
& \sum_{t \in \mathcal{T}} \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t} \right)\eta^{ch}_{st} \Delta t - c^{ch-} \leq C_{st} E^{max}_{st} \\
&\text{Single Ancillary Services Energy Coverage}&\\
& sb_{stc,p,t}  \eta^{ch}_{st} N_{p} \Delta t \le E_{st}^{max} - e^{st}_{t} & \forall p \in \mathcal{P}^{as_{dn}} \ \forall t \in \mathcal{T}\\
& sb_{std,p,t}  \frac{1}{\eta^{ds}_{st}} N_{p} \Delta t \leq e^{st}_{t}- E^{min}_{st} & \forall p \in \mathcal{P}^{as_{up}}, \ \forall t \in \mathcal{T}\\
& sb_{stc,p,1}  \eta^{ch}_{st} N_{p} \Delta t \le E_{st}^{max} - e^{st}_0 & \forall p \in \mathcal{P}^{as_{dn}}\\
& sb_{stc,p,t}  \eta^{ch}_{st} N_{p} \Delta t \le E_{st}^{max} - e^{st}_{t-1} & \forall p \in \mathcal{P}^{as_{dn}} \ \forall t \in \mathcal{T} \setminus 1\\
&sb_{std,p,1}  \frac{1}{\eta^{ds}_{st}} N_{p} \Delta t \leq e^{st}_0 - E^{min}_{st} & \forall p \in \mathcal{P}^{as_{up}}\\
& sb_{std,p,t}  \frac{1}{\eta^{ds}_{st}} N_{p} \Delta t \leq e^{st}_{t-1} - E^{min}_{st} & \forall p \in \mathcal{P}^{as_{up}}, \ \forall t \in \mathcal{T} \setminus 1 \\
&\text{Complete Ancillary Services Energy Coverage. Used when \texttt{"complete\_coverage" => true}}&\\
& \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}}  sb_{stc,p,t}  \eta^{ch}_{st} N_{p} \Delta t \le E_{st}^{max} - e^{st}_{t} & \forall t \in \mathcal{T}\\
& \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} sb_{std,p,t}  \frac{1}{\eta^{ds}_{st}} N_{p} \Delta t \leq e^{st}_{t}- E^{min}_{st} & \forall t \in \mathcal{T}\\
& \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} sb_{stc,p,1}  \eta^{ch}_{st} N_{p} \Delta t \le E_{st}^{max} - e^{st}_0 &\\
&\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}}  sb_{stc,p,t} \eta^{ch}_{st} N_{p} \Delta t \le E_{st}^{max} - e^{st}_{t-1} & \forall t \in \mathcal{T} \setminus 1\\
&\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} sb_{std,p,1}  \frac{1}{\eta^{ds}_{st}} N_{p} \Delta t \leq e^{st}_0- E^{min}_{st} & \\
& \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} sb_{std,p,t}  \frac{1}{\eta^{ds}_{st}} N_{p} \Delta t \leq e^{st}_{t-1}- E^{min}_{st} & \forall t \in \mathcal{T} \setminus 1\\
&\text{Regularization Constraints. Used when \texttt{"regularization" => true}}&\\
& \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t-1} sb_{stc,p,t-1} + p^{st,ch}_{t-1}  - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t-1} sb_{stc,p,t-1}\right) &\\
& - \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t}  - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{stc,p,t}\right) \le z^{st, ch}_{t} & \forall t \in \mathcal{T} \setminus 1\\
& \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t-1} sb_{stc,p,t-1} + p^{st,ch}_{t-1}  - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t-1} sb_{stc,p,t-1}\right) &\\
& - \left(\sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{stc,p,t} + p^{st,ch}_{t}  - \sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{stc,p,t}\right) \ge -z^{st, ch}_{t} & \forall t \in \mathcal{T} \setminus 1\\
&\left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t-1} sb_{std,p,t-1} + p^{st,ds}_{t-1} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t-1} sb_{std,p,t-1}\right) &\\
&-\left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{std,p,t-1} + p^{st,ds}_{t} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{std,p,t}\right) \le z^{st, ds}_{t}  & \forall t \in \mathcal{T} \setminus 1\\
&\left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t-1} sb_{std,p,t-1} + p^{st,ds}_{t-1} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t-1} sb_{std,p,t-1}\right) &\\
&-\left(\sum_{p \in \mathcal{P}^{\text{as}_\text{up}}} R^*_{p,t} sb_{std,p,t} + p^{st,ds}_{t} - \sum_{p \in \mathcal{P}^{\text{as}_\text{dn}}} R^*_{p,t} sb_{std,p,t}\right) \ge -z^{st, ds}_{t}  & \forall t \in \mathcal{T} \setminus 1
\end{aligned}
```
