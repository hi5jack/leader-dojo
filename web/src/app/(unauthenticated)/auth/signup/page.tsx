import { Metadata } from "next";

import { AuthCard, AuthFooterLink } from "@/components/common/auth-card";
import { SignUpForm } from "./sign-up-form";

export const metadata: Metadata = {
  title: "Create account · Leader Dojo",
};

export default function SignUpPage() {
  return (
    <AuthCard
      title="Create your Leader Dojo workspace"
      description="Set up your account to capture meetings, commitments, and reflections."
      footer={<AuthFooterLink href="/auth/signin" label="Already have an account? Sign in" />}
    >
      <SignUpForm />
    </AuthCard>
  );
}

