import type { Route } from "next";
import Link from "next/link";
import type { ReactNode } from "react";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

type AuthCardProps = {
  title: string;
  description: string;
  footer?: ReactNode;
  children: ReactNode;
};

export const AuthCard = ({ title, description, footer, children }: AuthCardProps) => {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-muted/40 px-4">
      <div className="w-full max-w-md">
        <Card>
          <CardHeader className="space-y-3">
            <CardTitle className="text-2xl font-semibold">{title}</CardTitle>
            <CardDescription>{description}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">{children}</CardContent>
        </Card>
        {footer ? <div className="mt-4 text-center text-sm text-muted-foreground">{footer}</div> : null}
      </div>
    </div>
  );
};

export const AuthFooterLink = ({ href, label }: { href: Route; label: string }) => {
  return (
    <p>
      <Link href={href} className="font-medium text-primary hover:underline">
        {label}
      </Link>
    </p>
  );
};

