export default function RootLoading() {
  return (
    <div className="grid min-h-screen place-items-center bg-muted/20">
      <div className="space-y-3 text-center">
        <p className="text-sm text-muted-foreground">Loading workspace...</p>
        <div className="mx-auto h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    </div>
  );
}

