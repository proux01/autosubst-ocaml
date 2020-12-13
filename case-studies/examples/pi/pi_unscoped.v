Require Export unscoped.
Require Export header_extensible.
Inductive chan : Type :=
    var_chan : forall _ : nat, chan.
Definition subst_chan (sigma_chan : forall _ : nat, chan) (s : chan) :
  chan := match s with
          | var_chan s0 => sigma_chan s0
          end.
Definition up_chan_chan (sigma : forall _ : nat, chan) :
  forall _ : nat, chan :=
  scons (var_chan var_zero)
    (funcomp (subst_chan (funcomp var_chan shift)) sigma).
Definition upId_chan_chan (sigma : forall _ : nat, chan)
  (Eq : forall x, eq (sigma x) (var_chan x)) :
  forall x, eq (up_chan_chan sigma x) (var_chan x) :=
  fun n =>
  match n with
  | S n' => ap (subst_chan (funcomp var_chan shift)) (Eq n')
  | O => eq_refl
  end.
Definition idSubst_chan (sigma_chan : forall _ : nat, chan)
  (Eq_chan : forall x, eq (sigma_chan x) (var_chan x)) (s : chan) :
  eq (subst_chan sigma_chan s) s :=
  match s with
  | var_chan s0 => Eq_chan s0
  end.
Definition upExt_chan_chan (sigma : forall _ : nat, chan)
  (tau : forall _ : nat, chan) (Eq : forall x, eq (sigma x) (tau x)) :
  forall x, eq (up_chan_chan sigma x) (up_chan_chan tau x) :=
  fun n =>
  match n with
  | S n' => ap (subst_chan (funcomp var_chan shift)) (Eq n')
  | O => eq_refl
  end.
Definition ext_chan (sigma_chan : forall _ : nat, chan)
  (tau_chan : forall _ : nat, chan)
  (Eq_chan : forall x, eq (sigma_chan x) (tau_chan x)) (s : chan) :
  eq (subst_chan sigma_chan s) (subst_chan tau_chan s) :=
  match s with
  | var_chan s0 => Eq_chan s0
  end.
Definition compSubstSubst_chan (sigma_chan : forall _ : nat, chan)
  (tau_chan : forall _ : nat, chan) (theta_chan : forall _ : nat, chan)
  (Eq_chan : forall x,
             eq (funcomp (subst_chan tau_chan) sigma_chan x) (theta_chan x))
  (s : chan) :
  eq (subst_chan tau_chan (subst_chan sigma_chan s))
    (subst_chan theta_chan s) := match s with
                                 | var_chan s0 => Eq_chan s0
                                 end.
Definition up_subst_subst_chan_chan (sigma : forall _ : nat, chan)
  (tau_chan : forall _ : nat, chan) (theta : forall _ : nat, chan)
  (Eq : forall x, eq (funcomp (subst_chan tau_chan) sigma x) (theta x)) :
  forall x,
  eq (funcomp (subst_chan (up_chan_chan tau_chan)) (up_chan_chan sigma) x)
    (up_chan_chan theta x) :=
  fun n =>
  match n with
  | S n' =>
      eq_trans
        (compSubstSubst_chan (funcomp var_chan shift) (up_chan_chan tau_chan)
           (funcomp (up_chan_chan tau_chan) shift) (fun x => eq_refl)
           (sigma n'))
        (eq_trans
           (eq_sym
              (compSubstSubst_chan tau_chan (funcomp var_chan shift)
                 (funcomp (subst_chan (funcomp var_chan shift)) tau_chan)
                 (fun x => eq_refl) (sigma n')))
           (ap (subst_chan (funcomp var_chan shift)) (Eq n')))
  | O => eq_refl
  end.
Lemma instId_chan : eq (subst_chan var_chan) id.
Proof.
exact (FunctionalExtensionality.functional_extensionality _ _
                (fun x => idSubst_chan var_chan (fun n => eq_refl) (id x))).
Qed.
Lemma varL_chan (sigma_chan : forall _ : nat, chan) :
  eq (funcomp (subst_chan sigma_chan) var_chan) sigma_chan.
Proof.
exact (FunctionalExtensionality.functional_extensionality _ _
                (fun x => eq_refl)).
Qed.
Inductive proc : Type :=
  | Nil : proc
  | Bang : forall _ : proc, proc
  | Res : forall _ : proc, proc
  | Par : forall _ : proc, forall _ : proc, proc
  | In : forall _ : chan, forall _ : proc, proc
  | Out : forall _ : chan, forall _ : chan, forall _ : proc, proc.
Lemma congr_Nil : eq Nil Nil.
Proof.
exact (eq_refl).
Qed.
Lemma congr_Bang {s0 : proc} {t0 : proc} (H0 : eq s0 t0) :
  eq (Bang s0) (Bang t0).
Proof.
exact (eq_trans eq_refl (ap (fun x => Bang x) H0)).
Qed.
Lemma congr_Res {s0 : proc} {t0 : proc} (H0 : eq s0 t0) :
  eq (Res s0) (Res t0).
Proof.
exact (eq_trans eq_refl (ap (fun x => Res x) H0)).
Qed.
Lemma congr_Par {s0 : proc} {s1 : proc} {t0 : proc} {t1 : proc}
  (H0 : eq s0 t0) (H1 : eq s1 t1) : eq (Par s0 s1) (Par t0 t1).
Proof.
exact (eq_trans (eq_trans eq_refl (ap (fun x => Par x s1) H0))
                (ap (fun x => Par t0 x) H1)).
Qed.
Lemma congr_In {s0 : chan} {s1 : proc} {t0 : chan} {t1 : proc}
  (H0 : eq s0 t0) (H1 : eq s1 t1) : eq (In s0 s1) (In t0 t1).
Proof.
exact (eq_trans (eq_trans eq_refl (ap (fun x => In x s1) H0))
                (ap (fun x => In t0 x) H1)).
Qed.
Lemma congr_Out {s0 : chan} {s1 : chan} {s2 : proc} {t0 : chan} {t1 : chan}
  {t2 : proc} (H0 : eq s0 t0) (H1 : eq s1 t1) (H2 : eq s2 t2) :
  eq (Out s0 s1 s2) (Out t0 t1 t2).
Proof.
exact (eq_trans
                (eq_trans (eq_trans eq_refl (ap (fun x => Out x s1 s2) H0))
                   (ap (fun x => Out t0 x s2) H1))
                (ap (fun x => Out t0 t1 x) H2)).
Qed.
Fixpoint subst_proc (sigma_chan : forall _ : nat, chan) (s : proc) : proc :=
  match s with
  | Nil => Nil
  | Bang s0 => Bang (subst_proc sigma_chan s0)
  | Res s0 => Res (subst_proc (up_chan_chan sigma_chan) s0)
  | Par s0 s1 => Par (subst_proc sigma_chan s0) (subst_proc sigma_chan s1)
  | In s0 s1 =>
      In (subst_chan sigma_chan s0) (subst_proc (up_chan_chan sigma_chan) s1)
  | Out s0 s1 s2 =>
      Out (subst_chan sigma_chan s0) (subst_chan sigma_chan s1)
        (subst_proc sigma_chan s2)
  end.
Fixpoint idSubst_proc (sigma_chan : forall _ : nat, chan)
(Eq_chan : forall x, eq (sigma_chan x) (var_chan x)) (s : proc) :
eq (subst_proc sigma_chan s) s :=
  match s with
  | Nil => congr_Nil
  | Bang s0 => congr_Bang (idSubst_proc sigma_chan Eq_chan s0)
  | Res s0 =>
      congr_Res
        (idSubst_proc (up_chan_chan sigma_chan) (upId_chan_chan _ Eq_chan) s0)
  | Par s0 s1 =>
      congr_Par (idSubst_proc sigma_chan Eq_chan s0)
        (idSubst_proc sigma_chan Eq_chan s1)
  | In s0 s1 =>
      congr_In (idSubst_chan sigma_chan Eq_chan s0)
        (idSubst_proc (up_chan_chan sigma_chan) (upId_chan_chan _ Eq_chan) s1)
  | Out s0 s1 s2 =>
      congr_Out (idSubst_chan sigma_chan Eq_chan s0)
        (idSubst_chan sigma_chan Eq_chan s1)
        (idSubst_proc sigma_chan Eq_chan s2)
  end.
Fixpoint ext_proc (sigma_chan : forall _ : nat, chan)
(tau_chan : forall _ : nat, chan)
(Eq_chan : forall x, eq (sigma_chan x) (tau_chan x)) (s : proc) :
eq (subst_proc sigma_chan s) (subst_proc tau_chan s) :=
  match s with
  | Nil => congr_Nil
  | Bang s0 => congr_Bang (ext_proc sigma_chan tau_chan Eq_chan s0)
  | Res s0 =>
      congr_Res
        (ext_proc (up_chan_chan sigma_chan) (up_chan_chan tau_chan)
           (upExt_chan_chan _ _ Eq_chan) s0)
  | Par s0 s1 =>
      congr_Par (ext_proc sigma_chan tau_chan Eq_chan s0)
        (ext_proc sigma_chan tau_chan Eq_chan s1)
  | In s0 s1 =>
      congr_In (ext_chan sigma_chan tau_chan Eq_chan s0)
        (ext_proc (up_chan_chan sigma_chan) (up_chan_chan tau_chan)
           (upExt_chan_chan _ _ Eq_chan) s1)
  | Out s0 s1 s2 =>
      congr_Out (ext_chan sigma_chan tau_chan Eq_chan s0)
        (ext_chan sigma_chan tau_chan Eq_chan s1)
        (ext_proc sigma_chan tau_chan Eq_chan s2)
  end.
Fixpoint compSubstSubst_proc (sigma_chan : forall _ : nat, chan)
(tau_chan : forall _ : nat, chan) (theta_chan : forall _ : nat, chan)
(Eq_chan : forall x,
           eq (funcomp (subst_chan tau_chan) sigma_chan x) (theta_chan x))
(s : proc) :
eq (subst_proc tau_chan (subst_proc sigma_chan s)) (subst_proc theta_chan s)
:=
  match s with
  | Nil => congr_Nil
  | Bang s0 =>
      congr_Bang
        (compSubstSubst_proc sigma_chan tau_chan theta_chan Eq_chan s0)
  | Res s0 =>
      congr_Res
        (compSubstSubst_proc (up_chan_chan sigma_chan)
           (up_chan_chan tau_chan) (up_chan_chan theta_chan)
           (up_subst_subst_chan_chan _ _ _ Eq_chan) s0)
  | Par s0 s1 =>
      congr_Par
        (compSubstSubst_proc sigma_chan tau_chan theta_chan Eq_chan s0)
        (compSubstSubst_proc sigma_chan tau_chan theta_chan Eq_chan s1)
  | In s0 s1 =>
      congr_In
        (compSubstSubst_chan sigma_chan tau_chan theta_chan Eq_chan s0)
        (compSubstSubst_proc (up_chan_chan sigma_chan)
           (up_chan_chan tau_chan) (up_chan_chan theta_chan)
           (up_subst_subst_chan_chan _ _ _ Eq_chan) s1)
  | Out s0 s1 s2 =>
      congr_Out
        (compSubstSubst_chan sigma_chan tau_chan theta_chan Eq_chan s0)
        (compSubstSubst_chan sigma_chan tau_chan theta_chan Eq_chan s1)
        (compSubstSubst_proc sigma_chan tau_chan theta_chan Eq_chan s2)
  end.
Lemma instId_proc : eq (subst_proc var_chan) id.
Proof.
exact (FunctionalExtensionality.functional_extensionality _ _
                (fun x => idSubst_proc var_chan (fun n => eq_refl) (id x))).
Qed.