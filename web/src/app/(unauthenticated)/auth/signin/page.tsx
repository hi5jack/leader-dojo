import { Metadata } from "next";

import { AuthCard, AuthFooterLink } from "@/components/common/auth-card";
import { SignInForm } from "./sign-in-form";

export const metadata: Metadata = {
  title: "Sign in · Leader Dojo",
};

export default function SignInPage() {
  return (
    <AuthCard
      title="Welcome back"
      description="Sign in to review your projects, commitments, and reflections."
      footer={<AuthFooterLink href="/auth/signup" label="Need an account? Create one" />}
    >
      <SignInForm />
    </AuthCard>
  );
}

